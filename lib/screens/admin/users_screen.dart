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
                      const AdminPill(
                        label: 'Company review',
                        color: AdminPalette.warning,
                        icon: Icons.verified_user_outlined,
                      ),
                      const SizedBox(width: 4),
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
    return AdminFilterChip(
      label: label,
      selected: isSelected,
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
    final statusColor = user.isActive
        ? AdminPalette.success
        : AdminPalette.danger;

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
                ProfileAvatar(user: user, radius: 18),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Text(
                              user.fullName,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontWeight: FontWeight.w700,
                                fontSize: 14,
                                color: AdminPalette.textPrimary,
                              ),
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
                      const SizedBox(height: 4),
                      Text(
                        user.email,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 11.5,
                          color: AdminPalette.textMuted,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        children: [
                          _buildRoleBadge(user.role),
                          if (user.role == 'company')
                            _buildApprovalBadge(user.normalizedApprovalStatus),
                          if (user.role == 'student' &&
                              academicLevel.isNotEmpty)
                            _buildLevelBadge(academicLevel),
                          AdminPill(
                            label: user.isActive ? 'Active' : 'Blocked',
                            color: statusColor,
                            icon: user.isActive
                                ? Icons.check_circle_outline_rounded
                                : Icons.block_outlined,
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
      ),
    );
  }

  Widget _buildRoleBadge(String role) {
    return AdminPill(label: role, color: _roleColor(role));
  }

  Widget _buildLevelBadge(String level) {
    return AdminPill(label: level, color: Colors.purple);
  }

  Widget _buildApprovalBadge(String status) {
    final normalized = status.trim().toLowerCase();
    final color = switch (normalized) {
      'pending' => AdminPalette.warning,
      'rejected' => AdminPalette.danger,
      _ => AdminPalette.success,
    };
    final label = switch (normalized) {
      'pending' => 'Pending review',
      'rejected' => 'Rejected',
      _ => 'Approved',
    };

    return AdminPill(
      label: label,
      color: color,
      icon: switch (normalized) {
        'pending' => Icons.pending_actions_rounded,
        'rejected' => Icons.gpp_bad_outlined,
        _ => Icons.verified_rounded,
      },
    );
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
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (sheetContext) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(18, 12, 18, 22),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildSheetHandle(),
              const SizedBox(height: 16),
              AdminSurface(
                padding: const EdgeInsets.all(12),
                radius: 18,
                child: Row(
                  children: [
                    ProfileAvatar(user: user, radius: 18),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            user.fullName,
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: AdminPalette.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            user.email,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 12,
                              color: AdminPalette.textMuted,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              _buildActionSheetTile(
                icon: Icons.person_outline_rounded,
                title: 'View Profile',
                subtitle: 'Open the full admin profile sheet for this user.',
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
                      'Unlock the company workspace and let this organization use the platform.',
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
                      'Keep the company blocked from the workspace until the profile is corrected.',
                  color: AdminPalette.danger,
                  onTap: () {
                    Navigator.pop(sheetContext);
                    _showCompanyApprovalDialog(user, provider, 'rejected');
                  },
                ),
              ],
              if (user.role == 'company' && !user.isCompanyPendingApproval) ...[
                const SizedBox(height: 10),
                _buildActionSheetTile(
                  icon: Icons.pending_actions_rounded,
                  title: 'Mark Pending Review',
                  subtitle:
                      'Move the company back into the review queue without blocking the account entirely.',
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
                    ? 'Temporarily disable account access.'
                    : 'Restore the account and let the user access the app again.',
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
    );
  }

  void _showCompanyApprovalDialog(
    UserModel user,
    AdminProvider provider,
    String nextStatus,
  ) {
    final actionLabel = switch (nextStatus) {
      'approved' => 'Approve',
      'rejected' => 'Reject',
      _ => 'Mark Pending',
    };
    final actionColor = switch (nextStatus) {
      'approved' => Colors.green,
      'rejected' => Colors.red,
      _ => Colors.orange,
    };

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: Text('$actionLabel Company'),
        content: Text(
          'Are you sure you want to ${actionLabel.toLowerCase()} ${user.companyName?.trim().isNotEmpty == true ? user.companyName!.trim() : user.fullName}?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              final error = await provider.updateCompanyApprovalStatus(
                user.uid,
                nextStatus,
              );
              if (!mounted) return;
              if (error != null && context.mounted) {
                ScaffoldMessenger.of(
                  context,
                ).showSnackBar(SnackBar(content: Text(error)));
              }
            },
            child: Text(
              actionLabel,
              style: TextStyle(color: actionColor, fontWeight: FontWeight.bold),
            ),
          ),
        ],
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
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        title: Text('$action User'),
        content: Text(
          'Are you sure you want to ${action.toLowerCase()} ${user.fullName}?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              final error = await provider.toggleUserActive(
                user.uid,
                !user.isActive,
              );
              if (!mounted) return;
              if (error != null && context.mounted) {
                ScaffoldMessenger.of(
                  context,
                ).showSnackBar(SnackBar(content: Text(error)));
              }
            },
            child: Text(
              action,
              style: TextStyle(
                color: user.isActive ? Colors.red : Colors.green,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showUserDetails(UserModel user) {
    showModalBottomSheet(
      context: context,
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
            return ListView(
              controller: scrollController,
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
              children: [
                _buildSheetHandle(),
                const SizedBox(height: 16),
                AdminSurface(
                  radius: 24,
                  gradient: AdminPalette.heroGradient(_roleColor(user.role)),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.12),
                  ),
                  child: Column(
                    children: [
                      ProfileAvatar(user: user, radius: 42),
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
                      const SizedBox(height: 8),
                      Wrap(
                        alignment: WrapAlignment.center,
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          AdminPill(label: user.role, color: Colors.white),
                          AdminPill(
                            label: user.isActive ? 'Active' : 'Blocked',
                            color: user.isActive
                                ? Colors.greenAccent.shade100
                                : Colors.red.shade100,
                            icon: user.isActive
                                ? Icons.check_circle_outline_rounded
                                : Icons.block_outlined,
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Text(
                        user.email,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 13,
                          color: Colors.white70,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 18),
                const AdminSectionHeader(
                  eyebrow: 'Profile',
                  title: 'User Details',
                  subtitle:
                      'Review identity, academic, and company information in a cleaner admin profile layout.',
                ),
                const SizedBox(height: 12),
                _buildDetailRow(Icons.email_outlined, 'Email', user.email),
                _buildDetailRow(
                  Icons.phone_outlined,
                  'Phone',
                  user.phone.isNotEmpty ? user.phone : 'Not provided',
                ),
                _buildDetailRow(
                  Icons.location_on_outlined,
                  'Location',
                  user.location.isNotEmpty ? user.location : 'Not provided',
                ),
                if (user.role == 'student') ...[
                  _buildDetailRow(
                    Icons.school_outlined,
                    'Academic Level',
                    user.academicLevel?.isNotEmpty == true
                        ? user.academicLevel!
                        : 'Not set',
                  ),
                  _buildDetailRow(
                    Icons.account_balance_outlined,
                    'University',
                    user.university?.isNotEmpty == true
                        ? user.university!
                        : 'Not set',
                  ),
                  _buildDetailRow(
                    Icons.subject_outlined,
                    'Field of Study',
                    user.fieldOfStudy?.isNotEmpty == true
                        ? user.fieldOfStudy!
                        : 'Not set',
                  ),
                ],
                if (user.role == 'student' &&
                    user.academicLevel == 'doctorat') ...[
                  _buildDetailRow(
                    Icons.science_outlined,
                    'Research Topic',
                    user.researchTopic?.isNotEmpty == true
                        ? user.researchTopic!
                        : 'Not set',
                  ),
                  _buildDetailRow(
                    Icons.biotech_outlined,
                    'Laboratory',
                    user.laboratory?.isNotEmpty == true
                        ? user.laboratory!
                        : 'Not set',
                  ),
                  _buildDetailRow(
                    Icons.person_outline_rounded,
                    'Supervisor',
                    user.supervisor?.isNotEmpty == true
                        ? user.supervisor!
                        : 'Not set',
                  ),
                  _buildDetailRow(
                    Icons.category_outlined,
                    'Research Domain',
                    user.researchDomain?.isNotEmpty == true
                        ? user.researchDomain!
                        : 'Not set',
                  ),
                ],
                if (user.role == 'company') ...[
                  _buildDetailRow(
                    Icons.business_outlined,
                    'Company',
                    user.companyName?.isNotEmpty == true
                        ? user.companyName!
                        : 'Not set',
                  ),
                  _buildDetailRow(
                    Icons.verified_user_outlined,
                    'Approval Status',
                    switch (user.normalizedApprovalStatus) {
                      'pending' => 'Pending review',
                      'rejected' => 'Rejected',
                      _ => 'Approved',
                    },
                  ),
                  _buildDetailRow(
                    Icons.category_outlined,
                    'Sector',
                    user.sector?.isNotEmpty == true ? user.sector! : 'Not set',
                  ),
                  _buildDetailRow(
                    Icons.language_outlined,
                    'Website',
                    user.website?.isNotEmpty == true
                        ? user.website!
                        : 'Not set',
                  ),
                ],
                if (user.role == 'student') ...[
                  const SizedBox(height: 6),
                  FutureBuilder<CvModel?>(
                    future: _cvService.getCvByStudentId(user.uid),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
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

  Widget _buildDetailRow(IconData icon, String label, String value) {
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
                  style: const TextStyle(
                    fontSize: 14,
                    height: 1.4,
                    color: AdminPalette.textPrimary,
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
