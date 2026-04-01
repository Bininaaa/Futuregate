import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../config/app_metadata.dart';
import '../../providers/auth_provider.dart';
import '../notifications_screen.dart';
import '../student/edit_profile_screen.dart';
import 'security_privacy_screen.dart';
import 'settings_flow_theme.dart';
import 'settings_flow_widgets.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final user = authProvider.userModel;

    if (user == null) {
      return const Scaffold(body: Center(child: Text('Not logged in')));
    }

    final providerLabel = authProvider.isEmailProvider
        ? 'Email & Password'
        : 'Google';

    return SettingsPageScaffold(
      title: 'Settings',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SettingsPanel(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Preferences', style: SettingsFlowTheme.heroTitle()),
                const SizedBox(height: 8),
                Text(
                  'Tune the app experience, review account details, and jump into the settings that matter most.',
                  style: SettingsFlowTheme.caption(),
                ),
                const SizedBox(height: 16),
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: [
                    SettingsStatusPill(
                      label: providerLabel,
                      color: SettingsFlowPalette.primary,
                    ),
                    SettingsStatusPill(
                      label: 'Version ${AppMetadata.version}',
                      color: SettingsFlowPalette.secondary,
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          const SettingsSectionHeading(
            title: 'Experience',
            subtitle:
                'Keep the page grounded in the current app behavior instead of introducing unsupported settings.',
          ),
          const SizedBox(height: 10),
          SettingsPanel(
            child: Column(
              children: [
                SettingsListRow(
                  icon: Icons.palette_outlined,
                  iconColor: SettingsFlowPalette.primary,
                  title: 'Appearance / Theme',
                  subtitle: 'Light visual system',
                  onTap: () => _showInfoSheet(
                    context,
                    title: 'Appearance / Theme',
                    message:
                        'This build currently uses a light visual system across the app. A global theme switch has not been wired yet.',
                  ),
                ),
                const SizedBox(height: 10),
                SettingsListRow(
                  icon: Icons.language_rounded,
                  iconColor: SettingsFlowPalette.secondary,
                  title: 'Language',
                  subtitle: 'English',
                  onTap: () => _showInfoSheet(
                    context,
                    title: 'Language',
                    message:
                        'The current app experience is shown in English. Broader language selection can be introduced safely in a later iteration.',
                  ),
                ),
                const SizedBox(height: 10),
                SettingsListRow(
                  icon: Icons.notifications_active_outlined,
                  iconColor: SettingsFlowPalette.accent,
                  title: 'Notification Preferences',
                  subtitle: 'Open your notifications center',
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const NotificationsScreen(),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          const SettingsSectionHeading(
            title: 'Account',
            subtitle:
                'Use the existing profile and security flows already connected to your account.',
          ),
          const SizedBox(height: 10),
          SettingsPanel(
            child: Column(
              children: [
                SettingsListRow(
                  icon: Icons.person_outline_rounded,
                  iconColor: SettingsFlowPalette.primaryDark,
                  title: 'Account Preferences',
                  subtitle: user.role == 'student'
                      ? 'Update your profile details'
                      : 'Manage your profile details from the company profile area',
                  onTap: () {
                    if (user.role == 'student') {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const EditProfileScreen(),
                        ),
                      );
                      return;
                    }

                    _showInfoSheet(
                      context,
                      title: 'Account Preferences',
                      message:
                          'Company profile editing remains available from the company profile area to preserve the current company-specific flow.',
                    );
                  },
                ),
                const SizedBox(height: 10),
                SettingsListRow(
                  icon: Icons.lock_outline_rounded,
                  iconColor: SettingsFlowPalette.warning,
                  title: 'Security & Privacy',
                  subtitle: 'Passwords, email updates, privacy, and legal info',
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const SecurityPrivacyScreen(),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                SettingsListRow(
                  icon: Icons.info_outline_rounded,
                  iconColor: SettingsFlowPalette.secondary,
                  title: 'App Version',
                  subtitle: AppMetadata.version,
                  trailing: SettingsStatusPill(
                    label: 'Current',
                    color: SettingsFlowPalette.success,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showInfoSheet(
    BuildContext context, {
    required String title,
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
                const SizedBox(height: 14),
                Text(title, style: SettingsFlowTheme.sectionTitle()),
                const SizedBox(height: 10),
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
