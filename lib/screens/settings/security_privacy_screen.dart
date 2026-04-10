import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/auth_provider.dart';
import 'account_security_screens.dart';
import 'settings_flow_theme.dart';
import 'settings_flow_widgets.dart';

class SecurityPrivacyScreen extends StatelessWidget {
  const SecurityPrivacyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final user = authProvider.userModel;
    final hasGoogleProvider = authProvider.hasGoogleProvider;
    final hasPasswordProvider = authProvider.hasPasswordProvider;
    final canAddPassword = authProvider.canAddPassword;
    final canChangePassword = authProvider.canChangePassword;
    final canChangeEmail = authProvider.canChangeEmail;
    final providerLabel = authProvider.linkedProviderLabel;

    return SettingsPageScaffold(
      title: 'Security & Privacy',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SettingsPanel(
            padding: const EdgeInsets.all(18),
            color: SettingsFlowPalette.surfaceTint,
            border: Border.all(
              color: SettingsFlowPalette.primary.withValues(alpha: 0.10),
            ),
            child: SettingsAdaptiveHeader(
              leading: Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  gradient: SettingsFlowPalette.primaryGradient,
                  borderRadius: SettingsFlowTheme.radius(20),
                ),
                child: const Icon(
                  Icons.shield_rounded,
                  color: Colors.white,
                  size: 30,
                ),
              ),
              content: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Your account protection hub',
                    style: SettingsFlowTheme.sectionTitle(),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    'Update credentials, review privacy touchpoints, and keep access to your AvenirDZ profile secure.',
                    style: SettingsFlowTheme.caption(),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 18),
          const SettingsSectionHeading(
            title: 'Account Security',
            subtitle:
                'Use the existing account tools safely without affecting your current sign-in flow.',
          ),
          const SizedBox(height: 10),
          SettingsPanel(
            child: Column(
              children: [
                if (canAddPassword) ...[
                  SettingsListRow(
                    icon: Icons.password_rounded,
                    iconColor: SettingsFlowPalette.primary,
                    title: 'Add Password',
                    subtitle: 'Keep Google sign-in and add email/password too',
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const AddPasswordScreen(),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                ],
                if (canChangePassword) ...[
                  SettingsListRow(
                    icon: Icons.password_rounded,
                    iconColor: SettingsFlowPalette.primary,
                    title: 'Change Password',
                    subtitle: 'Update your sign-in password',
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const ChangePasswordScreen(),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                ],
                if (canChangeEmail) ...[
                  SettingsListRow(
                    icon: Icons.alternate_email_rounded,
                    iconColor: SettingsFlowPalette.secondary,
                    title: 'Change Email',
                    subtitle: user?.email.isNotEmpty == true
                        ? 'Current: ${user!.email}'
                        : 'Verify a new sign-in email',
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const ChangeEmailScreen(),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                ],
                if (hasGoogleProvider) ...[
                  SettingsInfoBanner(
                    icon: Icons.link_rounded,
                    title: hasPasswordProvider
                        ? 'Google-linked account'
                        : 'Google-managed account',
                    message: hasPasswordProvider
                        ? 'This account can sign in with both Google and email/password, but the sign-in email stays managed through Google.'
                        : 'This account signs in with Google. You can add a password if you want email/password access too, but the sign-in email itself stays managed through Google.',
                    color: SettingsFlowPalette.secondary,
                  ),
                  const SizedBox(height: 10),
                ],
                SettingsListRow(
                  icon: Icons.verified_user_outlined,
                  iconColor: SettingsFlowPalette.success,
                  title: 'Two-step verification',
                  subtitle: hasGoogleProvider
                      ? 'Manage it through your Google account'
                      : 'Available through your email provider',
                  onTap: () => _showDetailsSheet(
                    context,
                    title: 'Two-step verification',
                    icon: Icons.verified_user_outlined,
                    message: hasGoogleProvider
                        ? 'This account signs in with $providerLabel, so two-step verification is managed directly by Google.'
                        : 'A dedicated in-app two-step setup is not enabled yet. For now, keep your mailbox protected and use a strong password.',
                  ),
                ),
                const SizedBox(height: 10),
                SettingsListRow(
                  icon: Icons.devices_rounded,
                  iconColor: SettingsFlowPalette.accent,
                  title: 'Manage sessions & devices',
                  subtitle: 'Review where your account is being used',
                  onTap: () => _showDetailsSheet(
                    context,
                    title: 'Sessions & devices',
                    icon: Icons.devices_rounded,
                    message:
                        'Remote session management is not available in this build yet. Your active session on this device remains protected by Firebase authentication.',
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          const SettingsSectionHeading(
            title: 'Privacy Controls',
            subtitle:
                'Understand what information is stored and how it is used inside the platform.',
          ),
          const SizedBox(height: 10),
          SettingsPanel(
            child: Column(
              children: [
                SettingsListRow(
                  icon: Icons.tune_rounded,
                  iconColor: SettingsFlowPalette.primaryDark,
                  title: 'Data permissions',
                  subtitle:
                      'Profile, CV, and application data are used to power opportunities and recruiter review flows.',
                  onTap: () => _showDetailsSheet(
                    context,
                    title: 'Data permissions',
                    icon: Icons.tune_rounded,
                    message:
                        'AvenirDZ stores the profile details, CV content, saved items, and application activity needed to match students with opportunities and support application review.',
                  ),
                ),
                const SizedBox(height: 10),
                SettingsListRow(
                  icon: Icons.privacy_tip_outlined,
                  iconColor: SettingsFlowPalette.secondary,
                  title: 'Privacy Policy',
                  subtitle: 'Read how personal information is handled',
                  onTap: () => _showDetailsSheet(
                    context,
                    title: 'Privacy Policy',
                    icon: Icons.privacy_tip_outlined,
                    message:
                        'Your account data is used to provide sign-in, profile management, saved opportunities, notifications, CV access, and applications. Sensitive access is limited to the platform features that require it.',
                  ),
                ),
                const SizedBox(height: 10),
                SettingsListRow(
                  icon: Icons.gavel_rounded,
                  iconColor: SettingsFlowPalette.warning,
                  title: 'Terms of Use',
                  subtitle: 'Review expected platform usage',
                  onTap: () => _showDetailsSheet(
                    context,
                    title: 'Terms of Use',
                    icon: Icons.gavel_rounded,
                    message:
                        'Use AvenirDZ responsibly, keep account information accurate, and avoid submitting misleading applications or content that violates platform rules.',
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showDetailsSheet(
    BuildContext context, {
    required String title,
    required IconData icon,
    required String message,
  }) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        return SafeArea(
          child: Container(
            margin: const EdgeInsets.all(14),
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: SettingsFlowPalette.surface,
              borderRadius: SettingsFlowTheme.radius(24),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 42,
                    height: 4,
                    decoration: BoxDecoration(
                      color: SettingsFlowPalette.border,
                      borderRadius: SettingsFlowTheme.radius(999),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    SettingsIconBox(
                      icon: icon,
                      color: SettingsFlowPalette.primary,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        title,
                        style: SettingsFlowTheme.sectionTitle(),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(message, style: SettingsFlowTheme.caption()),
                const SizedBox(height: 16),
                SettingsPrimaryButton(
                  label: 'Close',
                  onPressed: () => Navigator.pop(sheetContext),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
