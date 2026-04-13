import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/user_model.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/profile_avatar.dart';
import 'settings_flow_theme.dart';
import 'settings_flow_widgets.dart';

Future<void> showLogoutConfirmationSheet(BuildContext context) async {
  await showModalBottomSheet<void>(
    context: context,
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
    isDismissible: false,
    enableDrag: false,
    useRootNavigator: true,
    builder: (sheetContext) => const LogoutConfirmationSheet(),
  );
}

class LogoutConfirmationSheet extends StatefulWidget {
  const LogoutConfirmationSheet({super.key});

  @override
  State<LogoutConfirmationSheet> createState() =>
      _LogoutConfirmationSheetState();
}

class _LogoutConfirmationSheetState extends State<LogoutConfirmationSheet> {
  late final UserModel? _user;
  late final _LogoutCopy _copy;
  bool _isSigningOut = false;

  @override
  void initState() {
    super.initState();
    _user = context.read<AuthProvider>().userModel;
    _copy = _LogoutCopy.fromRole(_user?.role);
  }

  Future<void> _signOut() async {
    if (_isSigningOut) {
      return;
    }

    setState(() => _isSigningOut = true);

    try {
      await context.read<AuthProvider>().logout();
    } catch (_) {
      if (mounted) {
        setState(() => _isSigningOut = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: !_isSigningOut,
      child: SafeArea(
        top: false,
        child: Align(
          alignment: Alignment.bottomCenter,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 460),
            child: Container(
              margin: const EdgeInsets.all(14),
              padding: const EdgeInsets.fromLTRB(18, 14, 18, 18),
              decoration: BoxDecoration(
                color: SettingsFlowPalette.surface,
                borderRadius: SettingsFlowTheme.radius(28),
                border: Border.all(color: SettingsFlowPalette.border),
                boxShadow: SettingsFlowTheme.softShadow(0.14),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 42,
                    height: 5,
                    decoration: BoxDecoration(
                      color: SettingsFlowPalette.border,
                      borderRadius: SettingsFlowTheme.radius(999),
                    ),
                  ),
                  const SizedBox(height: 18),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 54,
                        height: 54,
                        decoration: BoxDecoration(
                          color: _copy.color.withValues(alpha: 0.10),
                          borderRadius: SettingsFlowTheme.radius(18),
                        ),
                        child: Icon(_copy.icon, color: _copy.color, size: 26),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _copy.title,
                              style: SettingsFlowTheme.sectionTitle(),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              _copy.message,
                              style: SettingsFlowTheme.caption(),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  if (_user != null) ...[
                    const SizedBox(height: 16),
                    _LogoutAccountPreview(user: _user, copy: _copy),
                  ],
                  const SizedBox(height: 18),
                  SettingsButtonGroup(
                    children: [
                      SettingsSecondaryButton(
                        label: 'Cancel',
                        onPressed: _isSigningOut
                            ? null
                            : () => Navigator.pop(context),
                      ),
                      SettingsPrimaryButton(
                        label: _isSigningOut ? 'Signing out' : 'Sign out',
                        backgroundColor: SettingsFlowPalette.error,
                        onPressed: _isSigningOut ? null : _signOut,
                      ),
                    ],
                  ),
                  if (_isSigningOut) ...[
                    const SizedBox(height: 12),
                    const LinearProgressIndicator(
                      minHeight: 3,
                      color: SettingsFlowPalette.error,
                      backgroundColor: SettingsFlowPalette.dangerTint,
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _LogoutCopy {
  final String title;
  final String message;
  final String roleLabel;
  final IconData icon;
  final Color color;

  const _LogoutCopy({
    required this.title,
    required this.message,
    required this.roleLabel,
    required this.icon,
    required this.color,
  });

  factory _LogoutCopy.fromRole(String? role) {
    switch ((role ?? '').trim().toLowerCase()) {
      case 'admin':
        return const _LogoutCopy(
          title: 'Sign out of admin?',
          message:
              'You will leave the admin workspace on this device. Saved changes stay safe.',
          roleLabel: 'Admin',
          icon: Icons.admin_panel_settings_rounded,
          color: SettingsFlowPalette.primary,
        );
      case 'company':
        return const _LogoutCopy(
          title: 'Sign out of company?',
          message:
              'You will leave the company workspace on this device. Your profile and opportunities stay saved.',
          roleLabel: 'Company',
          icon: Icons.business_center_rounded,
          color: SettingsFlowPalette.secondary,
        );
      case 'student':
        return const _LogoutCopy(
          title: 'Sign out of student?',
          message:
              'You will leave your student workspace on this device. Your profile and saved items stay safe.',
          roleLabel: 'Student',
          icon: Icons.school_rounded,
          color: SettingsFlowPalette.primary,
        );
      default:
        return const _LogoutCopy(
          title: 'Sign out of FutureGate?',
          message: 'You can sign back in anytime with the same account.',
          roleLabel: 'Account',
          icon: Icons.logout_rounded,
          color: SettingsFlowPalette.primary,
        );
    }
  }
}

class _LogoutAccountPreview extends StatelessWidget {
  final UserModel user;
  final _LogoutCopy copy;

  const _LogoutAccountPreview({required this.user, required this.copy});

  @override
  Widget build(BuildContext context) {
    final displayName = _displayName(user);

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: SettingsFlowPalette.surfaceTint,
        borderRadius: SettingsFlowTheme.radius(18),
        border: Border.all(color: SettingsFlowPalette.border),
      ),
      child: Row(
        children: [
          ProfileAvatar(user: user, radius: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  displayName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: SettingsFlowTheme.cardTitle(),
                ),
                const SizedBox(height: 2),
                Text(
                  user.email.trim(),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: SettingsFlowTheme.caption(),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
            decoration: BoxDecoration(
              color: copy.color.withValues(alpha: 0.10),
              borderRadius: SettingsFlowTheme.radius(999),
            ),
            child: Text(
              copy.roleLabel,
              style: SettingsFlowTheme.micro(copy.color),
            ),
          ),
        ],
      ),
    );
  }

  String _displayName(UserModel user) {
    final companyName = (user.companyName ?? '').trim();
    final fullName = user.fullName.trim();

    if (user.isCompany && companyName.isNotEmpty) {
      return companyName;
    }

    if (fullName.isNotEmpty) {
      return fullName;
    }

    return user.isAdmin ? 'Admin account' : 'FutureGate account';
  }
}
