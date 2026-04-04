import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../providers/admin_provider.dart';
import '../../models/cv_model.dart';
import '../../models/user_model.dart';
import '../../services/cv_service.dart';
import '../../services/document_access_service.dart';
import '../../utils/admin_palette.dart';
import '../../utils/display_text.dart';
import '../../widgets/admin/admin_ui.dart';
import '../../widgets/profile_avatar.dart';

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
  final CvService _cvService = CvService();
  final DocumentAccessService _documentAccessService = DocumentAccessService();
  bool _didOpenInitialTarget = false;

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
    final provider = context.watch<AdminProvider>();
    final isLevelFilterActive = provider.userLevelFilter != 'all';

    if (provider.usersLoading) {
      return const Center(
        child: CircularProgressIndicator(color: AdminPalette.primary),
      );
    }

    if (provider.usersError != null && provider.allUsers.isEmpty) {
      return AdminEmptyState(
        icon: Icons.group_off_rounded,
        title: 'Users could not be loaded',
        message: provider.usersError!,
        action: FilledButton(
          onPressed: provider.loadAllUsers,
          child: const Text('Retry'),
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
                    const AdminSectionHeader(
                      eyebrow: 'Control',
                      title: 'User Management',
                      subtitle:
                          'Search quickly, filter by role or level, and review account status without jumping around the admin area.',
                    ),
                    const SizedBox(height: 14),
                    Wrap(
                      spacing: 10,
                      runSpacing: 10,
                      children: [
                        AdminPill(
                          label: '${provider.totalUsersCount} users',
                          color: AdminPalette.primary,
                          icon: Icons.people_alt_outlined,
                        ),
                        AdminPill(
                          label: '${provider.activeUsersCount} active',
                          color: AdminPalette.success,
                          icon: Icons.check_circle_outline_rounded,
                        ),
                        AdminPill(
                          label: '${provider.blockedUsersCount} blocked',
                          color: AdminPalette.danger,
                          icon: Icons.block_outlined,
                        ),
                        AdminPill(
                          label: '${provider.adminUsersCount} admins',
                          color: AdminPalette.accent,
                          icon: Icons.admin_panel_settings_outlined,
                        ),
                        AdminPill(
                          label:
                              '${provider.pendingCompanyUsersCount} company reviews',
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
                hintText: 'Search by name or email...',
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
                    _buildRoleChip('All', 'all', provider),
                    const SizedBox(width: 8),
                    _buildRoleChip('Students', 'student', provider),
                    const SizedBox(width: 8),
                    _buildRoleChip('Companies', 'company', provider),
                    const SizedBox(width: 8),
                    _buildRoleChip('Admins', 'admin', provider),
                    const SizedBox(width: 8),
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
                      const AdminPill(
                        label: 'Level filters',
                        color: AdminPalette.info,
                        icon: Icons.school_outlined,
                      ),
                      const SizedBox(width: 4),
                      _buildLevelChip('All', 'all', provider),
                      const SizedBox(width: 6),
                      _buildLevelChip('Bac', 'bac', provider),
                      const SizedBox(width: 6),
                      _buildLevelChip('Licence', 'licence', provider),
                      const SizedBox(width: 6),
                      _buildLevelChip('Master', 'master', provider),
                      const SizedBox(width: 6),
                      _buildLevelChip('Doctorat', 'doctorat', provider),
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
                        label: 'Company review',
                        color: AdminPalette.warning,
                        icon: isLevelFilterActive
                            ? Icons.lock_outline_rounded
                            : Icons.verified_user_outlined,
                      ),
                      const SizedBox(width: 4),
                      if (isLevelFilterActive) ...[
                        const AdminPill(
                          label: 'Disabled while level filter is active',
                          color: AdminPalette.textMuted,
                          icon: Icons.info_outline_rounded,
                        ),
                        const SizedBox(width: 6),
                      ],
                      _buildCompanyApprovalChip('All', 'all', provider),
                      const SizedBox(width: 6),
                      _buildCompanyApprovalChip('Pending', 'pending', provider),
                      const SizedBox(width: 6),
                      _buildCompanyApprovalChip(
                        'Approved',
                        'approved',
                        provider,
                      ),
                      const SizedBox(width: 6),
                      _buildCompanyApprovalChip(
                        'Rejected',
                        'rejected',
                        provider,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          if (provider.allUsers.isEmpty)
            const SliverFillRemaining(
              hasScrollBody: false,
              child: AdminEmptyState(
                icon: Icons.people_outline_rounded,
                title: 'No users found',
                message:
                    'Try another search or relax the current role and level filters.',
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
                          border: Border.all(color: Colors.white, width: 2),
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
                                        style: const TextStyle(
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
                                        style: TextStyle(
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
                                  style: const TextStyle(
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
                            tooltip: 'User actions',
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
          ? (user.isActive ? 'Active' : 'Blocked')
          : (user.isActive ? 'Active' : 'Blocked'),
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
          label: 'Approve',
          icon: Icons.verified_rounded,
          color: AdminPalette.success,
          filled: true,
          onPressed: () =>
              _showCompanyApprovalDialog(user, provider, 'approved'),
        ),
      if (user.isCompanyPendingApproval)
        _buildCompanyQuickActionButton(
          label: 'Reject',
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
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
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
      'pending' => 'Pending review',
      'rejected' => 'Rejected',
      _ => 'Approved',
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
        label: user.isActive ? 'Active' : 'Blocked',
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
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.7,
                          color: Colors.white70,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        user.fullName,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        subtitle,
                        style: const TextStyle(
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
                  style: const TextStyle(
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
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  subtitle,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
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
                Text(
                  user.email,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 13, color: Colors.white70),
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
        color: Colors.white.withValues(alpha: 0.96),
        border: Border.all(color: Colors.white.withValues(alpha: 0.18)),
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
    final actionLabel = user.isActive ? 'Block User' : 'Unblock User';
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
                    eyebrow: 'Quick actions',
                    subtitle:
                        'Choose the next moderation step or open the full profile.',
                  ),
                  const SizedBox(height: 12),
                  _buildActionSheetTile(
                    icon: Icons.person_outline_rounded,
                    title: 'View Profile',
                    subtitle:
                        'Open the full admin profile sheet for this user.',
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
                      title: 'Approve Company',
                      subtitle:
                          'Unlock the company workspace and move it into the approved state.',
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
                      title: 'Reject Company',
                      subtitle:
                          'Keep the company out of the workspace until the profile is corrected.',
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
                      title: 'Mark Pending Review',
                      subtitle:
                          'Move the company back into the review queue for another check.',
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
                        ? 'Temporarily remove access to this account.'
                        : 'Restore access and let the user sign in again.',
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
      'approved' => 'Approve Company',
      'rejected' => 'Reject Company',
      _ => 'Mark Pending Review',
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
      'approved' =>
        'This will unlock the workspace and let the company use its approved features right away.',
      'rejected' =>
        'This will keep the company out of the workspace until the profile details are corrected.',
      _ =>
        'This will move the company back into the review queue for another moderation pass.',
    };

    _showConfirmationDialog(
      eyebrow: 'Company moderation',
      title: actionLabel,
      message: message,
      targetLabel: companyLabel,
      targetHint: 'Selected company',
      icon: actionIcon,
      accentColor: actionColor,
      confirmLabel: switch (nextStatus) {
        'approved' => 'Approve',
        'rejected' => 'Reject',
        _ => 'Set Pending',
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
              color: Colors.white,
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
                        style: const TextStyle(
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
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    color: AdminPalette.textPrimary,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  message,
                  style: const TextStyle(
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
                              style: const TextStyle(
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
                              style: const TextStyle(
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
                    label: 'Cancel',
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
                        ScaffoldMessenger.of(
                          context,
                        ).showSnackBar(SnackBar(content: Text(error)));
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
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: AdminPalette.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: const TextStyle(
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
    final action = user.isActive ? 'Block' : 'Unblock';
    _showConfirmationDialog(
      eyebrow: 'Account access',
      title: '$action User',
      message: user.isActive
          ? 'This will immediately remove access to the app until you restore the account later.'
          : 'This will restore access and let the user sign in and use the app again.',
      targetLabel: user.fullName,
      targetHint: 'Selected account',
      icon: user.isActive
          ? Icons.block_outlined
          : Icons.check_circle_outline_rounded,
      accentColor: user.isActive ? AdminPalette.danger : AdminPalette.success,
      confirmLabel: action,
      onConfirm: () => provider.toggleUserActive(user.uid, !user.isActive),
    );
  }

  void _showUserDetails(UserModel user) {
    final provider = context.read<AdminProvider>();

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
                      user: user,
                      eyebrow: 'Profile overview',
                      subtitle:
                          'Review identity, status, and submitted information in one place.',
                    ),
                    const SizedBox(height: 18),
                    const AdminSectionHeader(
                      eyebrow: 'Profile',
                      title: 'User Details',
                      subtitle:
                          'Review contact info, account status, and role-specific details in one clean profile view.',
                    ),
                    const SizedBox(height: 12),
                    _buildDetailRow(Icons.email_outlined, 'Email', user.email),
                    _buildOptionalDetailRow(
                      Icons.phone_outlined,
                      'Phone',
                      user.phone,
                      'No phone number added',
                    ),
                    _buildOptionalDetailRow(
                      Icons.location_on_outlined,
                      'Location',
                      user.location,
                      'No location added',
                    ),
                    if (user.role == 'student') ...[
                      _buildOptionalDetailRow(
                        Icons.school_outlined,
                        'Academic Level',
                        user.academicLevel,
                        'No academic level added',
                      ),
                      _buildOptionalDetailRow(
                        Icons.account_balance_outlined,
                        'University',
                        user.university,
                        'No university added',
                      ),
                      _buildOptionalDetailRow(
                        Icons.subject_outlined,
                        'Field of Study',
                        user.fieldOfStudy,
                        'No field of study added',
                      ),
                    ],
                    if (user.role == 'student' &&
                        user.academicLevel == 'doctorat') ...[
                      _buildOptionalDetailRow(
                        Icons.science_outlined,
                        'Research Topic',
                        user.researchTopic,
                        'No research topic added',
                      ),
                      _buildOptionalDetailRow(
                        Icons.biotech_outlined,
                        'Laboratory',
                        user.laboratory,
                        'No laboratory added',
                      ),
                      _buildOptionalDetailRow(
                        Icons.person_outline_rounded,
                        'Supervisor',
                        user.supervisor,
                        'No supervisor assigned',
                      ),
                      _buildOptionalDetailRow(
                        Icons.category_outlined,
                        'Research Domain',
                        user.researchDomain,
                        'No research domain added',
                      ),
                    ],
                    if (user.role == 'company') ...[
                      _buildOptionalDetailRow(
                        Icons.business_outlined,
                        'Company',
                        user.companyName,
                        'No company name added',
                      ),
                      _buildDetailRow(
                        Icons.verified_user_outlined,
                        'Approval Status',
                        _approvalDisplayLabel(user.normalizedApprovalStatus),
                      ),
                      _buildCompanyModerationPanel(user, provider),
                      _buildOptionalDetailRow(
                        Icons.category_outlined,
                        'Sector',
                        user.sector,
                        'No sector added',
                      ),
                      _buildOptionalDetailRow(
                        Icons.language_outlined,
                        'Website',
                        user.website,
                        'No website added',
                      ),
                    ],
                    if (user.role == 'student') ...[
                      const SizedBox(height: 6),
                      FutureBuilder<CvModel?>(
                        future: _cvService.getCvByStudentId(user.uid),
                        builder: (context, snapshot) {
                          if (snapshot.connectionState ==
                              ConnectionState.waiting) {
                            return const Padding(
                              padding: EdgeInsets.symmetric(vertical: 12),
                              child: LinearProgressIndicator(),
                            );
                          }

                          return _buildStudentCvSection(user, snapshot.data);
                        },
                      ),
                    ],
                    if (user.role == 'company') ...[
                      const SizedBox(height: 6),
                      _buildCompanyCommercialRegisterSection(user),
                    ],
                    if (user.bio?.isNotEmpty == true)
                      _buildDetailRow(
                        Icons.person_outline_rounded,
                        'Bio',
                        user.bio!,
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
          label: 'Approve Company',
          icon: Icons.verified_rounded,
          onPressed: () =>
              _showCompanyApprovalDialog(user, provider, 'approved'),
          color: AdminPalette.success,
        ),
      if (!user.isCompanyRejected)
        _buildDocumentButton(
          label: 'Reject Company',
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
          const Text(
            'Moderation Actions',
            style: TextStyle(
              fontSize: 13.5,
              fontWeight: FontWeight.w700,
              color: AdminPalette.textPrimary,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Update the company approval state from here without leaving the profile.',
            style: TextStyle(
              fontSize: 12,
              height: 1.45,
              color: AdminPalette.textMuted,
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

  Widget _buildSectionCopy(String title, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: AdminPalette.textPrimary,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          value,
          style: const TextStyle(
            fontSize: 12.5,
            height: 1.5,
            color: AdminPalette.textSecondary,
          ),
        ),
      ],
    );
  }

  Widget _buildStudentCvSection(UserModel user, CvModel? cv) {
    return AdminSurface(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(16),
      radius: 20,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const AdminSectionHeader(
            eyebrow: 'Documents',
            title: 'Student CV',
            subtitle:
                'Review the uploaded CV and the built CV export without leaving the user profile.',
          ),
          const SizedBox(height: 14),
          _buildSectionCopy(
            'Primary CV',
            cv == null
                ? 'No CV has been created for this user yet.'
                : cv.hasUploadedCv
                ? 'Primary CV: ${cv.uploadedCvDisplayName}'
                : 'No primary CV uploaded',
          ),
          const SizedBox(height: 6),
          _buildSectionCopy(
            'Built CV',
            cv == null
                ? 'Built CV unavailable'
                : cv.hasExportedPdf
                ? 'Built CV PDF available'
                : cv.hasBuilderContent
                ? 'Built CV information available'
                : 'Built CV unavailable',
          ),
          if (cv != null && cv.hasUploadedCv) ...[
            const SizedBox(height: 12),
            _buildAdaptiveActionGroup([
              _buildDocumentButton(
                label: 'View CV',
                icon: Icons.visibility_outlined,
                onPressed: cv.isUploadedCvPdf
                    ? () => _openUserCvDocument(
                        user.uid,
                        variant: 'primary',
                        requirePdf: true,
                      )
                    : null,
                color: AdminPalette.accent,
              ),
              _buildDocumentButton(
                label: 'Download CV',
                icon: Icons.download_outlined,
                onPressed: () => _openUserCvDocument(
                  user.uid,
                  variant: 'primary',
                  download: true,
                ),
                color: AdminPalette.accent,
                outlined: true,
              ),
            ]),
            if (!cv.isUploadedCvPdf) ...[
              const SizedBox(height: 10),
              const Text(
                'The uploaded file is not a valid PDF.',
                style: TextStyle(
                  fontSize: 12,
                  color: AdminPalette.warning,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ],
          if (cv != null && cv.hasExportedPdf) ...[
            const SizedBox(height: 10),
            _buildAdaptiveActionGroup([
              _buildDocumentButton(
                label: 'View Built CV',
                icon: Icons.picture_as_pdf_outlined,
                onPressed: () => _openUserCvDocument(
                  user.uid,
                  variant: 'built',
                  requirePdf: true,
                ),
                color: AdminPalette.primaryDark,
              ),
              _buildDocumentButton(
                label: 'Download Built CV',
                icon: Icons.download_outlined,
                onPressed: () => _openUserCvDocument(
                  user.uid,
                  variant: 'built',
                  download: true,
                ),
                color: AdminPalette.primaryDark,
                outlined: true,
              ),
            ]),
          ],
        ],
      ),
    );
  }

  Widget _buildCompanyCommercialRegisterSection(UserModel user) {
    final uploadedAt = user.commercialRegisterUploadedAt;
    final uploadedAtLabel = uploadedAt == null
        ? 'Not available'
        : DateFormat('MMM d, yyyy').format(uploadedAt.toDate());

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: const Color(0xFFFF8C00).withValues(alpha: 0.14),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'سجل تجاري',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: Color(0xFF2D1B4E),
            ),
          ),
          const SizedBox(height: 8),
          if (user.hasCommercialRegister) ...[
            Text(
              user.commercialRegisterFileName.isNotEmpty
                  ? user.commercialRegisterFileName
                  : 'Commercial Register uploaded',
              style: TextStyle(fontSize: 12, color: Colors.grey[700]),
            ),
            const SizedBox(height: 4),
            Text(
              'Uploaded: $uploadedAtLabel',
              style: TextStyle(fontSize: 12, color: Colors.grey[700]),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _openCommercialRegister(user.uid),
                    icon: const Icon(Icons.visibility_outlined, size: 18),
                    label: const Text('View سجل تجاري'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFFF8C00),
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () =>
                        _openCommercialRegister(user.uid, download: true),
                    icon: const Icon(Icons.download_outlined, size: 18),
                    label: const Text('Download سجل تجاري'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFFFF8C00),
                      side: BorderSide(
                        color: const Color(0xFFFF8C00).withValues(alpha: 0.24),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ] else
            Text(
              'Missing commercial register document.',
              style: TextStyle(
                fontSize: 12,
                color: Colors.red.shade600,
                fontWeight: FontWeight.w600,
              ),
            ),
        ],
      ),
    );
  }

  Future<void> _openUserCvDocument(
    String userId, {
    required String variant,
    bool download = false,
    bool requirePdf = false,
  }) async {
    final messenger = ScaffoldMessenger.of(context);

    try {
      final document = await _documentAccessService.getUserCvDocument(
        userId: userId,
        variant: variant,
      );

      if (requirePdf && !document.isPdf) {
        messenger.showSnackBar(
          const SnackBar(
            content: Text('This document is not a valid PDF file.'),
          ),
        );
        return;
      }

      final uri = Uri.tryParse(
        download ? document.downloadUrl : document.viewUrl,
      );
      if (uri == null) {
        throw Exception('File unavailable.');
      }

      final launched = await launchUrl(
        uri,
        mode: LaunchMode.platformDefault,
        webOnlyWindowName: '_blank',
      );
      if (!launched && mounted) {
        messenger.showSnackBar(
          const SnackBar(content: Text('Could not open the document.')),
        );
      }
    } catch (e) {
      if (!mounted) return;
      messenger.showSnackBar(SnackBar(content: Text(_documentErrorMessage(e))));
    }
  }

  Future<void> _openCommercialRegister(
    String companyId, {
    bool download = false,
  }) async {
    final messenger = ScaffoldMessenger.of(context);

    try {
      final document = await _documentAccessService
          .getCompanyCommercialRegister(companyId: companyId);
      final uri = Uri.tryParse(
        download ? document.downloadUrl : document.viewUrl,
      );
      if (uri == null) {
        throw Exception('File unavailable.');
      }

      final launched = await launchUrl(
        uri,
        mode: LaunchMode.platformDefault,
        webOnlyWindowName: '_blank',
      );
      if (!launched && mounted) {
        messenger.showSnackBar(
          const SnackBar(content: Text('Could not open the document.')),
        );
      }
    } catch (e) {
      if (!mounted) return;
      messenger.showSnackBar(SnackBar(content: Text(_documentErrorMessage(e))));
    }
  }

  String _documentErrorMessage(Object error) {
    final message = error.toString();
    if (message.contains('permission') || message.contains('403')) {
      return 'Permission denied while opening the document.';
    }
    if (message.contains('404') || message.contains('not found')) {
      return 'The requested document is no longer available.';
    }

    return 'Could not open the document right now.';
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
  }) {
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
                  style: const TextStyle(
                    fontSize: 11.5,
                    color: AdminPalette.textMuted,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: mutedValue ? 13.2 : 14,
                    height: 1.4,
                    color: mutedValue
                        ? AdminPalette.textMuted
                        : AdminPalette.textPrimary,
                    fontWeight: mutedValue ? FontWeight.w500 : FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
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
