import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../models/opportunity_model.dart';
import '../../providers/admin_provider.dart';
import '../../models/user_model.dart';
import '../../services/company_service.dart';
import '../../services/document_access_service.dart';
import '../../utils/admin_palette.dart';
import '../../utils/document_launch_helper.dart';
import '../../utils/display_text.dart';
import '../../utils/opportunity_metadata.dart';
import '../../utils/opportunity_type.dart';
import '../../l10n/generated/app_localizations.dart';
import '../../theme/app_typography.dart';
import '../../widgets/admin/admin_ui.dart';
import '../../widgets/profile_avatar.dart';
import '../../widgets/shared/app_feedback.dart';
import '../../widgets/shared/app_loading.dart';
import 'admin_student_profile_sheet.dart';

class UsersScreen extends StatefulWidget {
  const UsersScreen({
    super.key,
    this.initialRoleFilter = 'all',
    this.initialCompanyApprovalFilter = 'all',
    this.initialTargetId = '',
  });

  final String initialRoleFilter;
  final String initialCompanyApprovalFilter;
  final String initialTargetId;

  @override
  State<UsersScreen> createState() => _UsersScreenState();
}

class _UsersScreenState extends State<UsersScreen> {
  final TextEditingController _searchController = TextEditingController();
  final DocumentAccessService _documentAccessService = DocumentAccessService();
  bool _didOpenInitialTarget = false;

  AppLocalizations get _l10n => AppLocalizations.of(context)!;

  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      if (!mounted) return;
      final provider = context.read<AdminProvider>();
      provider.setUserRoleFilter(widget.initialRoleFilter);
      if (widget.initialRoleFilter == 'company' ||
          widget.initialRoleFilter == 'all') {
        provider.setCompanyApprovalFilter(widget.initialCompanyApprovalFilter);
      }
      provider.loadAllUsers().then((_) => _openInitialTargetIfNeeded());
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _openInitialTargetIfNeeded() {
    final targetId = widget.initialTargetId.trim();
    if (_didOpenInitialTarget || targetId.isEmpty || !mounted) {
      return;
    }

    final provider = context.read<AdminProvider>();
    UserModel? targetUser;
    for (final user in provider.rawUsers) {
      if (user.uid == targetId) {
        targetUser = user;
        break;
      }
    }
    if (targetUser == null) {
      return;
    }

    _didOpenInitialTarget = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }
      _showUserDetails(targetUser!);
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = _l10n;
    final provider = context.watch<AdminProvider>();
    final isLevelFilterActive = provider.userLevelFilter != 'all';

    if (provider.usersLoading) {
      return const AppLoadingView(density: AppLoadingDensity.compact);
    }

    if (provider.usersError != null && provider.allUsers.isEmpty) {
      return AdminEmptyState(
        icon: Icons.group_off_rounded,
        title: l10n.uiUsersCouldNotBeLoaded,
        message: provider.usersError!,
        action: FilledButton(
          onPressed: provider.loadAllUsers,
          child: Text(AppLocalizations.of(context)!.retryLabel),
        ),
      );
    }

    return RefreshIndicator(
      color: AdminPalette.primary,
      onRefresh: provider.loadAllUsers,
      child: CustomScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
              child: AdminSurface(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    AdminSectionHeader(
                      eyebrow: l10n.uiControl,
                      title: l10n.uiUserManagement,
                      subtitle: l10n
                          .uiSearchQuicklyFilterByRoleOrLevelAndReviewAccount,
                    ),
                    const SizedBox(height: 14),
                    Wrap(
                      spacing: 10,
                      runSpacing: 10,
                      children: [
                        AdminPill(
                          label:
                              '${provider.totalUsersCount} ${l10n.uiUsers.toLowerCase()}',
                          color: AdminPalette.primary,
                          icon: Icons.people_alt_outlined,
                        ),
                        AdminPill(
                          label:
                              '${provider.activeUsersCount} ${l10n.uiActive.toLowerCase()}',
                          color: AdminPalette.success,
                          icon: Icons.check_circle_outline_rounded,
                        ),
                        AdminPill(
                          label:
                              '${provider.blockedUsersCount} ${l10n.uiBlocked.toLowerCase()}',
                          color: AdminPalette.danger,
                          icon: Icons.block_outlined,
                        ),
                        AdminPill(
                          label:
                              '${provider.adminUsersCount} ${l10n.uiAdmins.toLowerCase()}',
                          color: AdminPalette.accent,
                          icon: Icons.admin_panel_settings_outlined,
                        ),
                        AdminPill(
                          label:
                              '${provider.pendingCompanyUsersCount} ${l10n.uiCompanyReview.toLowerCase()}',
                          color: AdminPalette.warning,
                          icon: Icons.pending_actions_rounded,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
              child: AdminSearchField(
                controller: _searchController,
                hintText: l10n.uiSearchByNameOrEmail,
                onChanged: provider.setUserSearch,
                onClear: () {
                  _searchController.clear();
                  provider.setUserSearch('');
                },
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _buildRoleChip(l10n.uiAll, 'all', provider),
                    const SizedBox(width: 8),
                    _buildRoleChip(l10n.uiStudents, 'student', provider),
                    const SizedBox(width: 8),
                    _buildRoleChip(l10n.uiCompanies, 'company', provider),
                    const SizedBox(width: 8),
                    _buildRoleChip(l10n.uiAdmins, 'admin', provider),
                    const SizedBox(width: 8),
                  ],
                ),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    AdminPill(
                      label: l10n.uiAccountState,
                      color: AdminPalette.danger,
                      icon: Icons.shield_outlined,
                    ),
                    const SizedBox(width: 4),
                    _buildAccessChip(l10n.uiAll, 'all', provider),
                    const SizedBox(width: 6),
                    _buildAccessChip(l10n.uiActive, 'active', provider),
                    const SizedBox(width: 6),
                    _buildAccessChip(l10n.uiBlocked, 'blocked', provider),
                  ],
                ),
              ),
            ),
          ),
          if (provider.userRoleFilter == 'student' ||
              provider.userRoleFilter == 'all')
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      AdminPill(
                        label: l10n.uiLevelFilters,
                        color: AdminPalette.info,
                        icon: Icons.school_outlined,
                      ),
                      const SizedBox(width: 4),
                      _buildLevelChip(l10n.uiAll, 'all', provider),
                      const SizedBox(width: 6),
                      _buildLevelChip(l10n.uiBac, 'bac', provider),
                      const SizedBox(width: 6),
                      _buildLevelChip(
                        l10n.academicLevelLicence,
                        'licence',
                        provider,
                      ),
                      const SizedBox(width: 6),
                      _buildLevelChip(
                        l10n.academicLevelMaster,
                        'master',
                        provider,
                      ),
                      const SizedBox(width: 6),
                      _buildLevelChip(
                        l10n.academicLevelDoctorat,
                        'doctorat',
                        provider,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          if (provider.userRoleFilter == 'company' ||
              provider.userRoleFilter == 'all')
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      AdminPill(
                        label: l10n.uiCompanyReview,
                        color: AdminPalette.warning,
                        icon: isLevelFilterActive
                            ? Icons.lock_outline_rounded
                            : Icons.verified_user_outlined,
                      ),
                      const SizedBox(width: 4),
                      if (isLevelFilterActive) ...[
                        AdminPill(
                          label: l10n.uiDisabledWhileLevelFilterIsActive,
                          color: AdminPalette.textMuted,
                          icon: Icons.info_outline_rounded,
                        ),
                        const SizedBox(width: 6),
                      ],
                      _buildCompanyApprovalChip(l10n.uiAll, 'all', provider),
                      const SizedBox(width: 6),
                      _buildCompanyApprovalChip(
                        l10n.uiPending,
                        'pending',
                        provider,
                      ),
                      const SizedBox(width: 6),
                      _buildCompanyApprovalChip(
                        l10n.uiApproved,
                        'approved',
                        provider,
                      ),
                      const SizedBox(width: 6),
                      _buildCompanyApprovalChip(
                        l10n.uiRejected,
                        'rejected',
                        provider,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          if (provider.allUsers.isEmpty)
            SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.fromLTRB(
                  0,
                  12,
                  0,
                  24 + MediaQuery.paddingOf(context).bottom,
                ),
                child: AdminEmptyState(
                  icon: Icons.people_outline_rounded,
                  title: l10n.uiNoUsersMatchThisSearch,
                  message: l10n
                      .uiTryAnotherSearchOrRelaxTheCurrentRoleAndLevelFilters,
                ),
              ),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate((context, index) {
                  return _buildUserCard(provider.allUsers[index], provider);
                }, childCount: provider.allUsers.length),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildRoleChip(String label, String value, AdminProvider provider) {
    final isSelected = provider.userRoleFilter == value;
    return AdminFilterChip(
      label: label,
      selected: isSelected,
      onTap: () => provider.setUserRoleFilter(value),
      icon: switch (value) {
        'student' => Icons.school_outlined,
        'company' => Icons.business_outlined,
        'admin' => Icons.admin_panel_settings_outlined,
        _ => Icons.filter_list_rounded,
      },
    );
  }

  Widget _buildLevelChip(String label, String value, AdminProvider provider) {
    final isSelected = provider.userLevelFilter == value;
    return AdminFilterChip(
      label: label,
      selected: isSelected,
      onTap: () => provider.setUserLevelFilter(value),
      icon: Icons.school_outlined,
    );
  }

  Widget _buildAccessChip(String label, String value, AdminProvider provider) {
    final isSelected = provider.userAccessFilter == value;
    return AdminFilterChip(
      label: label,
      selected: isSelected,
      onTap: () => provider.setUserAccessFilter(value),
      icon: switch (value) {
        'active' => Icons.check_circle_outline_rounded,
        'blocked' => Icons.block_outlined,
        _ => Icons.filter_list_rounded,
      },
    );
  }

  Widget _buildCompanyApprovalChip(
    String label,
    String value,
    AdminProvider provider,
  ) {
    final isSelected = provider.companyApprovalFilter == value;
    final isEnabled = provider.userLevelFilter == 'all';
    return AdminFilterChip(
      label: label,
      selected: isSelected,
      enabled: isEnabled,
      onTap: () => provider.setCompanyApprovalFilter(value),
      icon: switch (value) {
        'pending' => Icons.pending_actions_rounded,
        'approved' => Icons.verified_rounded,
        'rejected' => Icons.gpp_bad_outlined,
        _ => Icons.filter_list_rounded,
      },
    );
  }

  Widget _buildUserCard(UserModel user, AdminProvider provider) {
    final academicLevel = user.academicLevel?.trim() ?? '';
    final approvalStatus = user.normalizedApprovalStatus;
    final statusColor = _statusColorForUser(user);
    final roleColor = _roleColor(user.role);
    final roleLabel = _roleDisplayLabel(user.role);
    final levelLabel = user.role == 'student' && academicLevel.isNotEmpty
        ? DisplayText.capitalizeLeadingLabel(academicLevel)
        : '';

    return AdminSurface(
      margin: const EdgeInsets.only(bottom: 10),
      padding: EdgeInsets.zero,
      radius: 20,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: () => _showUserDetails(user),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 10, 12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Stack(
                  clipBehavior: Clip.none,
                  children: [
                    ProfileAvatar(user: user, radius: 19),
                    Positioned(
                      right: -1,
                      bottom: -1,
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: AdminPalette.surface,
                            width: 2,
                          ),
                        ),
                        child: Container(
                          width: 11,
                          height: 11,
                          decoration: BoxDecoration(
                            color: statusColor,
                            shape: BoxShape.circle,
                          ),
                        ),
                      ),
                    ),
                  ],
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
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  children: [
                                    Expanded(
                                      child: Text(
                                        user.fullName,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: AppTypography.product(
                                          fontWeight: FontWeight.w700,
                                          fontSize: 14.2,
                                          color: AdminPalette.textPrimary,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 3.5,
                                      ),
                                      decoration: BoxDecoration(
                                        color: roleColor.withValues(alpha: 0.1),
                                        borderRadius: BorderRadius.circular(
                                          999,
                                        ),
                                        border: Border.all(
                                          color: roleColor.withValues(
                                            alpha: 0.16,
                                          ),
                                        ),
                                      ),
                                      child: Text(
                                        roleLabel,
                                        style: AppTypography.product(
                                          fontSize: 10.3,
                                          fontWeight: FontWeight.w700,
                                          color: roleColor,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  user.email,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: AppTypography.product(
                                    fontSize: 11.5,
                                    color: AdminPalette.textMuted,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          _buildMiniActionButton(
                            icon: Icons.more_horiz_rounded,
                            tooltip: _l10n.uiUserActions,
                            onTap: () => _showUserActionsSheet(user, provider),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        children: [
                          if (levelLabel.isNotEmpty)
                            AdminPill(
                              label: levelLabel,
                              color: AdminPalette.info,
                              icon: Icons.school_outlined,
                            ),
                          if (user.role == 'company')
                            _buildApprovalBadge(approvalStatus),
                          if (_shouldShowAccountStateBadge(user))
                            _buildAccountStateBadge(user, color: statusColor),
                        ],
                      ),
                      if (user.role == 'company') ...[
                        const SizedBox(height: 10),
                        _buildCompanyQuickActions(user, provider),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  bool _shouldShowAccountStateBadge(UserModel user) {
    if (user.role != 'company') {
      return true;
    }

    if (!user.isActive) {
      return true;
    }

    return user.normalizedApprovalStatus == 'approved';
  }

  Color _statusColorForUser(UserModel user) {
    if (!user.isActive) {
      return AdminPalette.danger;
    }

    if (user.role != 'company') {
      return AdminPalette.success;
    }

    return switch (user.normalizedApprovalStatus) {
      'pending' => AdminPalette.warning,
      'rejected' => AdminPalette.danger,
      _ => AdminPalette.success,
    };
  }

  Widget _buildAccountStateBadge(UserModel user, {required Color color}) {
    final isCompany = user.role == 'company';

    return AdminPill(
      label: isCompany
          ? (user.isActive ? _l10n.uiActive : _l10n.uiBlocked)
          : (user.isActive ? _l10n.uiActive : _l10n.uiBlocked),
      color: color,
      icon: user.isActive
          ? Icons.check_circle_outline_rounded
          : Icons.block_outlined,
    );
  }

  Widget _buildCompanyQuickActions(UserModel user, AdminProvider provider) {
    final actions = <Widget>[
      if (!user.isCompanyApproved)
        _buildCompanyQuickActionButton(
          label: _l10n.uiApprove,
          icon: Icons.verified_rounded,
          color: AdminPalette.success,
          filled: true,
          onPressed: () =>
              _showCompanyApprovalDialog(user, provider, 'approved'),
        ),
      if (user.isCompanyPendingApproval)
        _buildCompanyQuickActionButton(
          label: _l10n.uiReject,
          icon: Icons.gpp_bad_outlined,
          color: AdminPalette.danger,
          onPressed: () =>
              _showCompanyApprovalDialog(user, provider, 'rejected'),
        ),
    ];

    if (actions.isEmpty) {
      return const SizedBox.shrink();
    }

    if (actions.length == 1) {
      return SizedBox(width: double.infinity, child: actions.first);
    }

    return Row(
      children: [
        Expanded(child: actions[0]),
        const SizedBox(width: 8),
        Expanded(child: actions[1]),
      ],
    );
  }

  Widget _buildCompanyQuickActionButton({
    required String label,
    required IconData icon,
    required Color color,
    required VoidCallback onPressed,
    bool filled = false,
  }) {
    final style = filled
        ? FilledButton.styleFrom(
            backgroundColor: color,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
          )
        : OutlinedButton.styleFrom(
            foregroundColor: color,
            side: BorderSide(color: color.withValues(alpha: 0.22)),
            padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
          );

    final child = Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(icon, size: 16),
        const SizedBox(width: 6),
        Flexible(
          child: Text(
            label,
            overflow: TextOverflow.ellipsis,
            style: AppTypography.product(
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    );

    if (filled) {
      return FilledButton(onPressed: onPressed, style: style, child: child);
    }

    return OutlinedButton(onPressed: onPressed, style: style, child: child);
  }

  String _approvalDisplayLabel(String status) {
    final normalized = status.trim().toLowerCase();
    return switch (normalized) {
      'pending' => _l10n.uiPendingReview,
      'rejected' => _l10n.uiRejected,
      _ => _l10n.uiApproved,
    };
  }

  Color _approvalDisplayColor(String status) {
    final normalized = status.trim().toLowerCase();

    return switch (normalized) {
      'pending' => AdminPalette.warning,
      'rejected' => AdminPalette.danger,
      _ => AdminPalette.success,
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

  IconData _roleIcon(String role) {
    return switch (role) {
      'student' => Icons.school_outlined,
      'company' => Icons.business_outlined,
      'admin' => Icons.admin_panel_settings_outlined,
      _ => Icons.person_outline_rounded,
    };
  }

  Widget _buildOverlayUserHeaderCard({
    required UserModel user,
    required String eyebrow,
    required String subtitle,
    bool compact = false,
  }) {
    final roleLabel = _roleDisplayLabel(user.role);
    final approvalLabel = user.role == 'company'
        ? _approvalDisplayLabel(user.normalizedApprovalStatus)
        : null;
    final avatarRadius = compact ? 20.0 : 42.0;

    final chips = <Widget>[
      AdminPill(
        label: roleLabel,
        color: Colors.white,
        icon: _roleIcon(user.role),
      ),
      if (approvalLabel != null)
        AdminPill(
          label: approvalLabel,
          color: Colors.white,
          icon: _approvalDisplayIcon(user.normalizedApprovalStatus),
        ),
      AdminPill(
        label: user.isActive ? _l10n.uiActive : _l10n.uiBlocked,
        color: Colors.white,
        icon: user.isActive
            ? Icons.check_circle_outline_rounded
            : Icons.block_outlined,
      ),
    ];

    return AdminSurface(
      radius: compact ? 22 : 24,
      padding: EdgeInsets.fromLTRB(
        compact ? 16 : 18,
        compact ? 16 : 20,
        compact ? 16 : 18,
        compact ? 16 : 20,
      ),
      gradient: AdminPalette.heroGradient(_roleColor(user.role)),
      border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
      child: compact
          ? Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildOverlayAvatar(
                  user: user,
                  radius: avatarRadius,
                  compact: true,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        eyebrow,
                        style: AppTypography.product(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.7,
                          color: Colors.white70,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        user.fullName,
                        style: AppTypography.product(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        subtitle,
                        style: AppTypography.product(
                          fontSize: 12.2,
                          color: Colors.white70,
                          height: 1.4,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Wrap(spacing: 8, runSpacing: 8, children: chips),
                    ],
                  ),
                ),
              ],
            )
          : Column(
              children: [
                Text(
                  eyebrow,
                  style: AppTypography.product(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.8,
                    color: Colors.white70,
                  ),
                ),
                const SizedBox(height: 12),
                _buildOverlayAvatar(user: user, radius: avatarRadius),
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
                  subtitle,
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
                _buildSingleLineText(
                  user.email,
                  textAlign: TextAlign.center,
                  style: AppTypography.product(
                    fontSize: 13,
                    color: Colors.white70,
                  ),
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

  Widget _buildApprovalBadge(String status) {
    return AdminPill(
      label: _approvalDisplayLabel(status),
      color: _approvalDisplayColor(status),
      icon: _approvalDisplayIcon(status),
    );
  }

  String _roleDisplayLabel(String role) {
    return DisplayText.capitalizeLeadingLabel(role);
  }

  Widget _buildMiniActionButton({
    required IconData icon,
    required String tooltip,
    required VoidCallback onTap,
  }) {
    return Tooltip(
      message: tooltip,
      child: Material(
        color: AdminPalette.surfaceMuted,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: SizedBox(
            width: 34,
            height: 34,
            child: Icon(icon, size: 18, color: AdminPalette.textPrimary),
          ),
        ),
      ),
    );
  }

  void _showUserActionsSheet(UserModel user, AdminProvider provider) {
    final l10n = _l10n;
    final actionLabel = user.isActive ? l10n.uiBlockUser : l10n.uiUnblockUser;
    final actionColor = user.isActive
        ? AdminPalette.danger
        : AdminPalette.success;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (sheetContext) => DraggableScrollableSheet(
        initialChildSize: 0.66,
        minChildSize: 0.36,
        maxChildSize: 0.9,
        expand: false,
        builder: (context, scrollController) => ClipRRect(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
          child: Material(
            color: AdminPalette.background,
            child: SafeArea(
              top: false,
              child: ListView(
                controller: scrollController,
                padding: const EdgeInsets.fromLTRB(18, 12, 18, 22),
                children: [
                  _buildSheetHandle(),
                  const SizedBox(height: 16),
                  _buildOverlayUserHeaderCard(
                    user: user,
                    compact: true,
                    eyebrow: l10n.uiQuickActions,
                    subtitle:
                        l10n.uiChooseTheNextModerationStepOrOpenTheFullProfile,
                  ),
                  const SizedBox(height: 12),
                  _buildActionSheetTile(
                    icon: Icons.person_outline_rounded,
                    title: l10n.uiViewProfile,
                    subtitle: l10n.uiOpenTheFullAdminProfileSheetForThisUser,
                    color: AdminPalette.primary,
                    onTap: () {
                      Navigator.pop(sheetContext);
                      _showUserDetails(user);
                    },
                  ),
                  if (user.role == 'company' && !user.isCompanyApproved) ...[
                    const SizedBox(height: 10),
                    _buildActionSheetTile(
                      icon: Icons.verified_rounded,
                      title: l10n.uiApproveCompany,
                      subtitle: l10n.uiApproveCompanySubtitle,
                      color: AdminPalette.success,
                      onTap: () {
                        Navigator.pop(sheetContext);
                        _showCompanyApprovalDialog(user, provider, 'approved');
                      },
                    ),
                  ],
                  if (user.role == 'company' && !user.isCompanyRejected) ...[
                    const SizedBox(height: 10),
                    _buildActionSheetTile(
                      icon: Icons.gpp_bad_outlined,
                      title: l10n.uiRejectCompany,
                      subtitle: l10n.uiRejectCompanySubtitle,
                      color: AdminPalette.danger,
                      onTap: () {
                        Navigator.pop(sheetContext);
                        _showCompanyApprovalDialog(user, provider, 'rejected');
                      },
                    ),
                  ],
                  if (user.role == 'company' &&
                      !user.isCompanyPendingApproval) ...[
                    const SizedBox(height: 10),
                    _buildActionSheetTile(
                      icon: Icons.pending_actions_rounded,
                      title: l10n.uiMarkPendingReview,
                      subtitle: l10n.uiMarkPendingSubtitle,
                      color: AdminPalette.warning,
                      onTap: () {
                        Navigator.pop(sheetContext);
                        _showCompanyApprovalDialog(user, provider, 'pending');
                      },
                    ),
                  ],
                  const SizedBox(height: 10),
                  _buildActionSheetTile(
                    icon: user.isActive
                        ? Icons.block_outlined
                        : Icons.check_circle_outline_rounded,
                    title: actionLabel,
                    subtitle: user.isActive
                        ? l10n.uiBlockUserSubtitle
                        : l10n.uiUnblockUserSubtitle,
                    color: actionColor,
                    onTap: () {
                      Navigator.pop(sheetContext);
                      _showToggleDialog(user, provider);
                    },
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _showCompanyApprovalDialog(
    UserModel user,
    AdminProvider provider,
    String nextStatus,
  ) {
    final companyLabel = user.companyName?.trim().isNotEmpty == true
        ? user.companyName!.trim()
        : user.fullName;
    final actionLabel = switch (nextStatus) {
      'approved' => _l10n.uiApproveCompany,
      'rejected' => _l10n.uiRejectCompany,
      _ => _l10n.uiMarkPendingReview,
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
      'approved' => _l10n.uiApproveCompanyMessage,
      'rejected' => _l10n.uiRejectCompanyMessage,
      _ => _l10n.uiMarkPendingCompanyMessage,
    };

    _showConfirmationDialog(
      eyebrow: _l10n.uiCompanyModeration,
      title: actionLabel,
      message: message,
      targetLabel: companyLabel,
      targetHint: _l10n.uiSelectedCompany,
      icon: actionIcon,
      accentColor: actionColor,
      confirmLabel: switch (nextStatus) {
        'approved' => _l10n.uiApprove,
        'rejected' => _l10n.uiReject,
        _ => _l10n.uiPending,
      },
      onConfirm: () =>
          provider.updateCompanyApprovalStatus(user.uid, nextStatus),
    );
  }

  void _showConfirmationDialog({
    required String eyebrow,
    required String title,
    required String message,
    required String targetLabel,
    required String targetHint,
    required IconData icon,
    required Color accentColor,
    required String confirmLabel,
    required Future<String?> Function() onConfirm,
  }) {
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
              border: Border.all(color: accentColor.withValues(alpha: 0.16)),
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
                        color: accentColor.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Icon(icon, color: accentColor, size: 24),
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
                        eyebrow,
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
                  title,
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
                          color: accentColor.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(icon, color: accentColor, size: 18),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              targetHint,
                              style: AppTypography.product(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: AdminPalette.textMuted,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              targetLabel,
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
                    label: AppLocalizations.of(context)!.cancelLabel,
                    icon: Icons.close_rounded,
                    onPressed: () => Navigator.pop(ctx),
                    color: AdminPalette.textMuted,
                    outlined: true,
                  ),
                  _buildDocumentButton(
                    label: confirmLabel,
                    icon: icon,
                    onPressed: () async {
                      Navigator.pop(ctx);
                      final error = await onConfirm();
                      if (!mounted) return;
                      if (error != null && context.mounted) {
                        context.showAppSnackBar(
                          error,
                          title: AppLocalizations.of(
                            context,
                          )!.updateUnavailableTitle,
                          type: AppFeedbackType.error,
                        );
                      }
                    },
                    color: accentColor,
                  ),
                ]),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildActionSheetTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: AdminSurface(
          padding: const EdgeInsets.all(14),
          radius: 18,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(icon, size: 22, color: color),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: AppTypography.product(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: AdminPalette.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: AppTypography.product(
                        fontSize: 12,
                        color: AdminPalette.textMuted,
                        height: 1.45,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Icon(Icons.chevron_right_rounded, color: color),
            ],
          ),
        ),
      ),
    );
  }

  void _showToggleDialog(UserModel user, AdminProvider provider) {
    _showConfirmationDialog(
      eyebrow: _l10n.uiAccountAccess,
      title: user.isActive ? _l10n.uiBlockUser : _l10n.uiUnblockUser,
      message: user.isActive
          ? _l10n.uiBlockUserMessage
          : _l10n.uiUnblockUserMessage,
      targetLabel: user.fullName,
      targetHint: _l10n.uiSelectedAccount,
      icon: user.isActive
          ? Icons.block_outlined
          : Icons.check_circle_outline_rounded,
      accentColor: user.isActive ? AdminPalette.danger : AdminPalette.success,
      confirmLabel: user.isActive ? _l10n.uiBlockUser : _l10n.uiUnblockUser,
      onConfirm: () => provider.toggleUserActive(user.uid, !user.isActive),
    );
  }

  UserModel? _currentUser(AdminProvider provider, String uid) {
    for (final candidate in provider.rawUsers) {
      if (candidate.uid == uid) {
        return candidate;
      }
    }
    return null;
  }

  String _companyDisplayName(UserModel user) {
    final companyName = (user.companyName ?? '').trim();
    if (companyName.isNotEmpty) {
      return companyName;
    }

    return user.fullName.trim().isEmpty ? user.email : user.fullName;
  }

  void _showUserDetails(UserModel user) {
    if (user.role == 'student') {
      showAdminStudentProfileSheet(context, user: user);
      return;
    }

    final companyPostingFuture = user.role == 'company'
        ? loadAdminCompanyOpportunities(user.uid)
        : null;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (ctx) {
        return DraggableScrollableSheet(
          initialChildSize: 0.76,
          minChildSize: 0.45,
          maxChildSize: 0.94,
          expand: false,
          builder: (context, scrollController) {
            final provider = context.watch<AdminProvider>();
            final liveUser = _currentUser(provider, user.uid) ?? user;

            return ClipRRect(
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(28),
              ),
              child: Material(
                color: AdminPalette.background,
                child: ListView(
                  controller: scrollController,
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
                  children: [
                    _buildSheetHandle(),
                    const SizedBox(height: 16),
                    _buildOverlayUserHeaderCard(
                      user: liveUser,
                      eyebrow: _l10n.uiProfileOverview,
                      subtitle: _l10n
                          .uiReviewIdentityStatusAndSubmittedInformationInOnePlace,
                    ),
                    const SizedBox(height: 18),
                    AdminSectionHeader(
                      eyebrow: _l10n.uiProfile,
                      title: _l10n.uiUserDetails,
                      subtitle: _l10n
                          .uiReviewContactInfoAccountStatusAndRoleSpecificDetailsInOneCleanProfileView,
                    ),
                    const SizedBox(height: 12),
                    _buildDetailRow(
                      Icons.email_outlined,
                      _l10n.uiEmail,
                      liveUser.email,
                      singleLineValue: true,
                    ),
                    _buildOptionalDetailRow(
                      Icons.phone_outlined,
                      _l10n.uiPhone,
                      liveUser.phone,
                      _l10n.uiNotProvided,
                    ),
                    _buildOptionalDetailRow(
                      Icons.location_on_outlined,
                      _l10n.uiLocation,
                      liveUser.location,
                      _l10n.uiNotProvided,
                    ),
                    if (liveUser.role == 'student') ...[
                      _buildOptionalDetailRow(
                        Icons.school_outlined,
                        _l10n.uiAcademicLevel,
                        liveUser.academicLevel,
                        _l10n.uiNotProvided,
                      ),
                      _buildOptionalDetailRow(
                        Icons.account_balance_outlined,
                        _l10n.uiUniversity,
                        liveUser.university,
                        _l10n.uiNotProvided,
                      ),
                      _buildOptionalDetailRow(
                        Icons.subject_outlined,
                        _l10n.uiFieldOfStudy81e26d,
                        liveUser.fieldOfStudy,
                        _l10n.uiNotProvided,
                      ),
                    ],
                    if (liveUser.role == 'student' &&
                        liveUser.academicLevel == 'doctorat') ...[
                      _buildOptionalDetailRow(
                        Icons.science_outlined,
                        _l10n.uiResearchTopic,
                        liveUser.researchTopic,
                        _l10n.uiNotProvided,
                      ),
                      _buildOptionalDetailRow(
                        Icons.biotech_outlined,
                        _l10n.uiLaboratory,
                        liveUser.laboratory,
                        _l10n.uiNotProvided,
                      ),
                      _buildOptionalDetailRow(
                        Icons.person_outline_rounded,
                        _l10n.uiSupervisor,
                        liveUser.supervisor,
                        _l10n.uiNotProvided,
                      ),
                      _buildOptionalDetailRow(
                        Icons.category_outlined,
                        _l10n.uiResearchDomain,
                        liveUser.researchDomain,
                        _l10n.uiNotProvided,
                      ),
                    ],
                    if (liveUser.role == 'company') ...[
                      _buildOptionalDetailRow(
                        Icons.business_outlined,
                        _l10n.uiCompanyName,
                        liveUser.companyName,
                        _l10n.uiNotProvided,
                      ),
                      _buildDetailRow(
                        Icons.verified_user_outlined,
                        _l10n.uiApprovalStatus,
                        _approvalDisplayLabel(
                          liveUser.normalizedApprovalStatus,
                        ),
                      ),
                      _buildCompanyModerationPanel(liveUser, provider),
                      _buildOptionalDetailRow(
                        Icons.category_outlined,
                        _l10n.uiSector,
                        liveUser.sector,
                        _l10n.uiNotProvided,
                      ),
                      _buildOptionalDetailRow(
                        Icons.language_outlined,
                        _l10n.uiWebsite,
                        liveUser.website,
                        _l10n.uiNotProvided,
                      ),
                      if ((liveUser.description ?? '').trim().isNotEmpty)
                        _buildDetailRow(
                          Icons.description_outlined,
                          _l10n.uiDescription,
                          liveUser.description!.trim(),
                        ),
                      if (companyPostingFuture != null)
                        _buildCompanyOpportunitiesSection(
                          liveUser,
                          future: companyPostingFuture,
                        ),
                    ],
                    if (liveUser.role == 'company') ...[
                      const SizedBox(height: 6),
                      _buildCompanyCommercialRegisterSection(liveUser),
                    ],
                    if (liveUser.bio?.isNotEmpty == true)
                      _buildDetailRow(
                        Icons.person_outline_rounded,
                        _l10n.uiBio,
                        liveUser.bio!,
                      ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
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

  Widget _buildSheetHandle() {
    return Center(
      child: Container(
        width: 46,
        height: 5,
        decoration: BoxDecoration(
          color: AdminPalette.border,
          borderRadius: BorderRadius.circular(999),
        ),
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

  Widget _buildCompanyModerationPanel(UserModel user, AdminProvider provider) {
    final buttons = <Widget>[
      if (!user.isCompanyApproved)
        _buildDocumentButton(
          label: _l10n.uiApproveCompany,
          icon: Icons.verified_rounded,
          onPressed: () =>
              _showCompanyApprovalDialog(user, provider, 'approved'),
          color: AdminPalette.success,
        ),
      if (!user.isCompanyRejected)
        _buildDocumentButton(
          label: _l10n.uiRejectCompany,
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
            _l10n.uiCompanyReview,
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

  Widget _buildCompanyCommercialRegisterSection(UserModel user) {
    final l10n = AppLocalizations.of(context)!;
    final uploadedAt = user.commercialRegisterUploadedAt;
    final uploadedAtLabel = uploadedAt == null
        ? _l10n.uiNotProvided
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
            _buildAdaptiveActionGroup([
              _buildDocumentButton(
                label: '${l10n.uiView} ${l10n.uiCommercialRegister}',
                icon: Icons.visibility_outlined,
                onPressed: () => _openCommercialRegister(user.uid),
                color: AdminPalette.accent,
              ),
              _buildDocumentButton(
                label: '${l10n.uiDownload} ${l10n.uiCommercialRegister}',
                icon: Icons.download_outlined,
                onPressed: () =>
                    _openCommercialRegister(user.uid, download: true),
                color: AdminPalette.accent,
                outlined: true,
              ),
            ]),
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
    } catch (e) {
      if (!mounted) return;
      context.showAppSnackBar(
        _documentErrorMessage(e, l10n),
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

  Widget _buildOptionalDetailRow(
    IconData icon,
    String label,
    String? value,
    String placeholder,
  ) {
    final trimmedValue = (value ?? '').trim();

    return _buildDetailRow(
      icon,
      label,
      trimmedValue.isNotEmpty ? trimmedValue : placeholder,
      mutedValue: trimmedValue.isEmpty,
    );
  }

  Widget _buildDetailRow(
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
                    ? _buildSingleLineText(value, style: valueStyle)
                    : Text(value, style: valueStyle),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSingleLineText(
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
}

class _AdminOpportunityDetailItem {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const _AdminOpportunityDetailItem({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });
}

class _AdminOpportunityDetailHero extends StatelessWidget {
  final String title;
  final String subtitle;
  final String typeLabel;
  final String statusLabel;
  final Color typeColor;
  final IconData icon;
  final bool isFeatured;
  final bool isHidden;

  const _AdminOpportunityDetailHero({
    required this.title,
    required this.subtitle,
    required this.typeLabel,
    required this.statusLabel,
    required this.typeColor,
    required this.icon,
    required this.isFeatured,
    required this.isHidden,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return AdminSurface(
      radius: 24,
      padding: const EdgeInsets.fromLTRB(18, 20, 18, 18),
      gradient: AdminPalette.heroGradient(typeColor),
      border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: Colors.white, size: 30),
          const SizedBox(height: 14),
          Text(
            title,
            style: AppTypography.product(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: Colors.white,
              height: 1.15,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            subtitle,
            style: AppTypography.product(
              fontSize: 13,
              color: Colors.white70,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              AdminPill(label: typeLabel, color: Colors.white, icon: icon),
              AdminPill(
                label: statusLabel,
                color: Colors.white,
                icon: Icons.radio_button_checked_rounded,
              ),
              if (isFeatured)
                AdminPill(
                  label: l10n.uiFeatured,
                  color: Colors.white,
                  icon: Icons.workspace_premium_outlined,
                ),
              if (isHidden)
                AdminPill(
                  label: l10n.uiHiddenLabel,
                  color: Colors.white,
                  icon: Icons.visibility_off_outlined,
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _AdminOpportunityDetailGrid extends StatelessWidget {
  final List<_AdminOpportunityDetailItem> items;

  const _AdminOpportunityDetailGrid({required this.items});

  @override
  Widget build(BuildContext context) {
    final visibleItems = items
        .where((item) => item.value.trim().isNotEmpty)
        .toList(growable: false);
    if (visibleItems.isEmpty) {
      return const SizedBox.shrink();
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final useTwoColumns = constraints.maxWidth >= 520;
        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: visibleItems.length,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: useTwoColumns ? 2 : 1,
            mainAxisExtent: 82,
            crossAxisSpacing: 10,
            mainAxisSpacing: 10,
          ),
          itemBuilder: (context, index) {
            final item = visibleItems[index];
            return AdminSurface(
              radius: 18,
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      color: item.color.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(13),
                    ),
                    child: Icon(item.icon, color: item.color, size: 19),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          item.label,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppTypography.product(
                            fontSize: 11.2,
                            color: AdminPalette.textMuted,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          item.value,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: AppTypography.product(
                            fontSize: 12.4,
                            color: AdminPalette.textPrimary,
                            fontWeight: FontWeight.w700,
                            height: 1.2,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}

class _AdminDetailTextSection extends StatelessWidget {
  final String title;
  final String text;
  final IconData icon;
  final Color color;

  const _AdminDetailTextSection({
    required this.title,
    required this.text,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return AdminSurface(
      radius: 18,
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _AdminDetailSectionTitle(title: title, icon: icon, color: color),
          const SizedBox(height: 10),
          Text(
            text,
            style: AppTypography.product(
              fontSize: 12.8,
              color: AdminPalette.textSecondary,
              height: 1.55,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

class _AdminDetailListSection extends StatelessWidget {
  final String title;
  final List<String> items;
  final IconData icon;
  final Color color;

  const _AdminDetailListSection({
    required this.title,
    required this.items,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return AdminSurface(
      radius: 18,
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _AdminDetailSectionTitle(title: title, icon: icon, color: color),
          const SizedBox(height: 10),
          ...items.map(
            (item) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 6,
                    height: 6,
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
                        fontSize: 12.8,
                        color: AdminPalette.textSecondary,
                        height: 1.45,
                        fontWeight: FontWeight.w600,
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
}

class _AdminDetailSectionTitle extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color color;

  const _AdminDetailSectionTitle({
    required this.title,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(11),
          ),
          child: Icon(icon, color: color, size: 17),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTypography.product(
              fontSize: 13,
              fontWeight: FontWeight.w800,
              color: AdminPalette.textPrimary,
            ),
          ),
        ),
      ],
    );
  }
}

Future<List<OpportunityModel>> loadAdminCompanyOpportunities(
  String companyId,
) async {
  final service = CompanyService();
  return service.getCompanyOpportunities(companyId);
}

class AdminCompanyOpportunitiesSheet extends StatefulWidget {
  const AdminCompanyOpportunitiesSheet({
    super.key,
    required this.companyId,
    required this.companyName,
  });

  final String companyId;
  final String companyName;

  @override
  State<AdminCompanyOpportunitiesSheet> createState() =>
      _AdminCompanyOpportunitiesSheetState();
}

class _AdminCompanyOpportunitiesSheetState
    extends State<AdminCompanyOpportunitiesSheet> {
  late Future<List<OpportunityModel>> _overviewFuture;

  @override
  void initState() {
    super.initState();
    _overviewFuture = _loadOverview();
  }

  Future<List<OpportunityModel>> _loadOverview() {
    return loadAdminCompanyOpportunities(widget.companyId);
  }

  void _retry() {
    setState(() {
      _overviewFuture = _loadOverview();
    });
  }

  void _showOpportunityDetails(OpportunityModel opportunity) {
    final l10n = AppLocalizations.of(context)!;
    final type = OpportunityType.parse(opportunity.type);
    final typeColor = OpportunityType.color(type);
    final status = opportunity.effectiveStatus();
    final statusLabel = status == 'open' ? l10n.uiOpen : l10n.uiClosed;
    final title = opportunity.title.trim().isEmpty
        ? l10n.uiUntitledOpportunity
        : opportunity.title.trim();
    final companyName = opportunity.companyName.trim().isEmpty
        ? l10n.uiUnknownCompany
        : opportunity.companyName.trim();
    final description = DisplayText.capitalizeLeadingLabel(
      opportunity.description,
    ).trim();
    final requirements = _detailList(
      opportunity.requirementItems.isNotEmpty
          ? opportunity.requirementItems
          : <String>[opportunity.requirements],
    );
    final benefits = _detailList(opportunity.benefits);
    final tags = _detailList(opportunity.tags);
    final workMode =
        OpportunityMetadata.formatWorkMode(opportunity.workMode) ?? '';
    final employmentType =
        OpportunityMetadata.formatEmploymentType(opportunity.employmentType) ??
        '';
    final paidStatus =
        OpportunityMetadata.formatPaidLabel(opportunity.isPaid) ?? '';
    final compensation = _compensationLabel(opportunity);
    final createdAt = opportunity.createdAt?.toDate();
    final postedLabel = createdAt == null
        ? ''
        : DateFormat('MMM d, yyyy').format(createdAt);

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (_) => DraggableScrollableSheet(
        initialChildSize: 0.82,
        minChildSize: 0.48,
        maxChildSize: 0.96,
        expand: false,
        builder: (context, scrollController) {
          return ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
            child: Material(
              color: AdminPalette.background,
              child: ListView(
                controller: scrollController,
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
                children: [
                  _buildHandle(),
                  const SizedBox(height: 16),
                  _AdminOpportunityDetailHero(
                    title: title,
                    subtitle: companyName,
                    typeLabel: OpportunityType.label(type, l10n),
                    statusLabel: statusLabel,
                    typeColor: typeColor,
                    icon: OpportunityType.icon(type),
                    isFeatured: opportunity.isFeatured,
                    isHidden: opportunity.isHidden,
                  ),
                  const SizedBox(height: 12),
                  _AdminOpportunityDetailGrid(
                    items: [
                      _AdminOpportunityDetailItem(
                        label: l10n.uiLocation,
                        value: _detailValue(
                          opportunity.location,
                          l10n.uiLocationNotSpecified,
                        ),
                        icon: Icons.location_on_outlined,
                        color: AdminPalette.info,
                      ),
                      _AdminOpportunityDetailItem(
                        label: l10n.uiDeadline,
                        value: _deadlineLabel(opportunity, l10n),
                        icon: Icons.event_outlined,
                        color: AdminPalette.activity,
                      ),
                      if (compensation.isNotEmpty)
                        _AdminOpportunityDetailItem(
                          label: l10n.uiCompensation,
                          value: compensation,
                          icon: Icons.payments_outlined,
                          color: AdminPalette.success,
                        ),
                      if (workMode.isNotEmpty)
                        _AdminOpportunityDetailItem(
                          label: l10n.uiWorkMode,
                          value: workMode,
                          icon: Icons.lan_outlined,
                          color: typeColor,
                        ),
                      if (employmentType.isNotEmpty)
                        _AdminOpportunityDetailItem(
                          label: l10n.uiEmploymentType,
                          value: employmentType,
                          icon: Icons.badge_outlined,
                          color: AdminPalette.primary,
                        ),
                      if (paidStatus.isNotEmpty)
                        _AdminOpportunityDetailItem(
                          label: l10n.uiPaidStatus,
                          value: paidStatus,
                          icon: Icons.account_balance_wallet_outlined,
                          color: AdminPalette.success,
                        ),
                      if ((opportunity.duration ?? '').trim().isNotEmpty)
                        _AdminOpportunityDetailItem(
                          label: l10n.uiDuration,
                          value: opportunity.duration!.trim(),
                          icon: Icons.schedule_outlined,
                          color: AdminPalette.textMuted,
                        ),
                      if (postedLabel.isNotEmpty)
                        _AdminOpportunityDetailItem(
                          label: l10n.uiPosted,
                          value: postedLabel,
                          icon: Icons.update_outlined,
                          color: AdminPalette.secondary,
                        ),
                    ],
                  ),
                  if (description.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    _AdminDetailTextSection(
                      title: l10n.uiDescription,
                      text: description,
                      icon: Icons.description_outlined,
                      color: typeColor,
                    ),
                  ],
                  if (requirements.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    _AdminDetailListSection(
                      title: l10n.requirementsLabel,
                      items: requirements,
                      icon: Icons.checklist_rounded,
                      color: typeColor,
                    ),
                  ],
                  if (benefits.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    _AdminDetailListSection(
                      title: l10n.uiBenefits,
                      items: benefits,
                      icon: Icons.workspace_premium_outlined,
                      color: AdminPalette.success,
                    ),
                  ],
                  if (tags.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    _AdminDetailListSection(
                      title: l10n.uiTags,
                      items: tags,
                      icon: Icons.sell_outlined,
                      color: AdminPalette.secondary,
                    ),
                  ],
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  String _detailValue(String value, String fallback) {
    final trimmed = value.trim();
    return trimmed.isEmpty
        ? fallback
        : DisplayText.capitalizeLeadingLabel(trimmed);
  }

  List<String> _detailList(List<String> values) {
    return values
        .map((item) => DisplayText.capitalizeLeadingLabel(item).trim())
        .where((item) => item.isNotEmpty)
        .toList(growable: false);
  }

  String _deadlineLabel(OpportunityModel opportunity, AppLocalizations l10n) {
    final deadline =
        opportunity.applicationDeadline ??
        OpportunityMetadata.parseDateTimeLike(opportunity.deadlineLabel);
    if (deadline != null) {
      return OpportunityMetadata.formatDateLabel(deadline);
    }

    return _detailValue(opportunity.deadlineLabel, l10n.uiNotSpecified);
  }

  String _compensationLabel(OpportunityModel opportunity) {
    final label = OpportunityType.isSponsoring(opportunity.type)
        ? opportunity.fundingLabel(preferFundingNote: true)
        : OpportunityMetadata.buildCompensationLabel(
            salaryMin: opportunity.salaryMin,
            salaryMax: opportunity.salaryMax,
            salaryCurrency: opportunity.salaryCurrency,
            salaryPeriod: opportunity.salaryPeriod,
            compensationText: opportunity.compensationText,
            isPaid: opportunity.isPaid,
            preferCompensationText: true,
          );

    return (label ?? '').trim();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return DraggableScrollableSheet(
      initialChildSize: 0.74,
      minChildSize: 0.42,
      maxChildSize: 0.94,
      expand: false,
      builder: (context, scrollController) {
        return ClipRRect(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
          child: Material(
            color: AdminPalette.background,
            child: FutureBuilder<List<OpportunityModel>>(
              future: _overviewFuture,
              builder: (context, snapshot) {
                final opportunities =
                    snapshot.data ?? const <OpportunityModel>[];
                final headline = switch (snapshot.connectionState) {
                  ConnectionState.waiting => l10n.uiLoadingOpportunities,
                  _ when opportunities.isEmpty =>
                    l10n.uiNoCompanyOpportunitiesYet,
                  _ =>
                    '${opportunities.length} ${l10n.uiPostedOpportunities.toLowerCase()}',
                };

                return ListView(
                  controller: scrollController,
                  padding: const EdgeInsets.fromLTRB(16, 10, 16, 20),
                  children: [
                    _buildHandle(),
                    const SizedBox(height: 12),
                    AdminSurface(
                      radius: 20,
                      gradient: AdminPalette.heroGradient(
                        AdminPalette.secondary,
                      ),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.12),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(
                            Icons.work_outline_rounded,
                            color: Colors.white,
                            size: 26,
                          ),
                          const SizedBox(height: 10),
                          Text(
                            widget.companyName.trim().isEmpty
                                ? l10n.uiCompanyOpportunities
                                : widget.companyName,
                            style: AppTypography.product(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            headline,
                            style: AppTypography.product(
                              fontSize: 12.5,
                              color: Colors.white70,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 10),
                    if (snapshot.connectionState == ConnectionState.waiting)
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 28),
                        child: Center(child: CircularProgressIndicator()),
                      )
                    else if (snapshot.hasError)
                      AdminEmptyState(
                        icon: Icons.work_off_outlined,
                        title: l10n.uiOpportunityHistoryUnavailable,
                        message: l10n.uiOpportunityHistoryUnavailableMessage,
                        action: FilledButton.icon(
                          onPressed: _retry,
                          icon: const Icon(Icons.refresh_rounded),
                          label: Text(l10n.retryLabel),
                        ),
                      )
                    else if (opportunities.isEmpty)
                      AdminEmptyState(
                        icon: Icons.work_outline_rounded,
                        title: l10n.uiNoOpportunitiesYet,
                        message: l10n.uiNoOpportunitiesPostedByCompany,
                      )
                    else
                      ...opportunities.map(
                        (opportunity) => _buildOpportunityCard(opportunity),
                      ),
                  ],
                );
              },
            ),
          ),
        );
      },
    );
  }

  Widget _buildHandle() {
    return Center(
      child: Container(
        width: 46,
        height: 5,
        decoration: BoxDecoration(
          color: AdminPalette.border,
          borderRadius: BorderRadius.circular(999),
        ),
      ),
    );
  }

  Widget _buildOpportunityCard(OpportunityModel opportunity) {
    final l10n = AppLocalizations.of(context)!;
    final status = opportunity.effectiveStatus();
    final statusColor = status == 'open'
        ? AdminPalette.success
        : AdminPalette.textMuted;
    final typeColor = OpportunityType.color(opportunity.type);
    final title = opportunity.title.trim().isEmpty
        ? l10n.uiUntitledOpportunity
        : opportunity.title.trim();
    final location = opportunity.location.trim();
    final statusLabel = status == 'open' ? l10n.uiOpen : l10n.uiClosed;
    final typeLabel = OpportunityType.label(opportunity.type, l10n);

    return Semantics(
      button: true,
      label: '$title, $typeLabel, $statusLabel. ${l10n.uiOpenDetails}',
      child: Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: Material(
          color: AdminPalette.surface,
          borderRadius: BorderRadius.circular(20),
          child: InkWell(
            onTap: () => _showOpportunityDetails(opportunity),
            borderRadius: BorderRadius.circular(20),
            child: Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: AdminPalette.border.withValues(alpha: 0.9),
                ),
                boxShadow: AdminPalette.softShadow,
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: typeColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Icon(
                      OpportunityType.icon(opportunity.type),
                      color: typeColor,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: AppTypography.product(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: AdminPalette.textPrimary,
                          ),
                        ),
                        if (location.isNotEmpty) ...[
                          const SizedBox(height: 4),
                          Text(
                            location,
                            style: AppTypography.product(
                              fontSize: 12.2,
                              color: AdminPalette.textSecondary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                        const SizedBox(height: 10),
                        Wrap(
                          spacing: 6,
                          runSpacing: 6,
                          children: [
                            AdminPill(
                              label: typeLabel,
                              color: typeColor,
                              icon: OpportunityType.icon(opportunity.type),
                            ),
                            AdminPill(
                              label: statusLabel,
                              color: statusColor,
                              icon: status == 'open'
                                  ? Icons.check_circle_outline_rounded
                                  : Icons.lock_outline_rounded,
                            ),
                            if (opportunity.isHidden)
                              AdminPill(
                                label: l10n.uiHiddenLabel,
                                color: AdminPalette.warning,
                                icon: Icons.visibility_off_outlined,
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Icon(
                    Icons.chevron_right_rounded,
                    size: 22,
                    color: AdminPalette.textMuted,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
