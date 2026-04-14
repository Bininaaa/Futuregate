import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../config/app_metadata.dart';
import '../../providers/auth_provider.dart';
import '../../theme/theme_controller.dart';
import '../company/profile_screen.dart';
import '../notifications_screen.dart';
import '../student/edit_profile_screen.dart';
import 'about_futuregate_screen.dart';
import 'help_center_screen.dart';
import 'logout_confirmation_sheet.dart';
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

    final providerLabel = authProvider.linkedProviderLabel;
    final isCompany = user.role == 'company';

    if (isCompany) {
      return SettingsPageScaffold(
        title: 'More',
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    SettingsFlowPalette.primaryDark,
                    SettingsFlowPalette.primary,
                    SettingsFlowPalette.secondary,
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: SettingsFlowTheme.radius(28),
                boxShadow: SettingsFlowTheme.softShadow(0.14),
              ),
              child: Stack(
                children: [
                  Positioned(
                    top: -28,
                    right: -20,
                    child: _HeroOrb(
                      size: 110,
                      color: Colors.white.withValues(alpha: 0.16),
                    ),
                  ),
                  Positioned(
                    bottom: -44,
                    left: -12,
                    child: _HeroOrb(
                      size: 92,
                      color: Colors.white.withValues(alpha: 0.10),
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Company workspace',
                        style: SettingsFlowTheme.micro(
                          Colors.white.withValues(alpha: 0.86),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Profile, security, and support all in one polished hub.',
                        style: SettingsFlowTheme.heroTitle(Colors.white),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        'Use this area to keep your brand presence sharp, stay on top of notifications, and manage the parts of the workspace you need most.',
                        style: SettingsFlowTheme.caption(
                          Colors.white.withValues(alpha: 0.84),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Wrap(
                        spacing: 10,
                        runSpacing: 10,
                        children: [
                          SettingsStatusPill(
                            label: providerLabel,
                            color: Colors.white,
                          ),
                          SettingsStatusPill(
                            label: 'Version ${AppMetadata.version}',
                            color: Colors.white,
                          ),
                          SettingsStatusPill(
                            label: (user.companyName ?? '').trim().isNotEmpty
                                ? (user.companyName ?? '').trim()
                                : 'Company account',
                            color: Colors.white,
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),
            const _ThemeSettingsSection(),
            const SizedBox(height: 18),
            const SettingsSectionHeading(
              title: 'Workspace',
              subtitle:
                  'Jump straight into the core areas that shape your company presence.',
            ),
            const SizedBox(height: 10),
            SettingsPanel(
              child: Column(
                children: [
                  SettingsListRow(
                    icon: Icons.apartment_rounded,
                    iconColor: SettingsFlowPalette.primary,
                    title: 'Company Profile',
                    subtitle: 'Preview your public-facing company presence',
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const CompanyProfileScreen(),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  SettingsListRow(
                    icon: Icons.edit_outlined,
                    iconColor: SettingsFlowPalette.accent,
                    title: 'Edit Company Profile',
                    subtitle:
                        'Refresh your description, contact info, and logo',
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const EditCompanyProfileScreen(),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  SettingsListRow(
                    icon: Icons.notifications_active_outlined,
                    iconColor: SettingsFlowPalette.secondary,
                    title: 'Notifications',
                    subtitle: 'Open your notifications center',
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const NotificationsScreen(),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  SettingsListRow(
                    icon: Icons.lock_outline_rounded,
                    iconColor: SettingsFlowPalette.warning,
                    title: 'Security & Privacy',
                    subtitle:
                        'Passwords, email updates, privacy, and legal info',
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const SecurityPrivacyScreen(),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),
            const SettingsSectionHeading(
              title: 'Support',
              subtitle: 'Helpful destinations beyond profile management.',
            ),
            const SizedBox(height: 10),
            SettingsPanel(
              child: Column(
                children: [
                  SettingsListRow(
                    icon: Icons.help_outline_rounded,
                    iconColor: SettingsFlowPalette.secondary,
                    title: 'Help Center',
                    subtitle: 'Browse FAQs and contact support',
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const HelpCenterScreen(),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  SettingsListRow(
                    icon: Icons.info_outline_rounded,
                    iconColor: SettingsFlowPalette.primaryDark,
                    title: 'About FutureGate',
                    subtitle: 'Mission, version, and platform details',
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const AboutFutureGateScreen(),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  SettingsListRow(
                    icon: Icons.verified_outlined,
                    iconColor: SettingsFlowPalette.success,
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
            const SizedBox(height: 18),
            SettingsPanel(
              color: SettingsFlowPalette.dangerTint,
              border: Border.all(
                color: SettingsFlowPalette.error.withValues(alpha: 0.16),
              ),
              child: SettingsListRow(
                icon: Icons.logout_rounded,
                iconColor: SettingsFlowPalette.error,
                title: 'Sign out',
                subtitle: 'Sign out of the company workspace',
                destructive: true,
                onTap: () => showLogoutConfirmationSheet(context),
              ),
            ),
          ],
        ),
      );
    }

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
            title: 'Theme',
            subtitle:
                'Choose the visual mode that feels best for your workspace.',
          ),
          const SizedBox(height: 10),
          const _ThemeSettingsPanel(),
          const SizedBox(height: 18),
          const SettingsSectionHeading(
            title: 'Experience',
            subtitle:
                'Keep notifications and language preferences close to your account.',
          ),
          const SizedBox(height: 10),
          SettingsPanel(
            child: Column(
              children: [
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
                  subtitle: 'Update your profile details',
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const EditProfileScreen(),
                    ),
                  ),
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
          const SizedBox(height: 18),
          SettingsPanel(
            color: SettingsFlowPalette.dangerTint,
            border: Border.all(
              color: SettingsFlowPalette.error.withValues(alpha: 0.16),
            ),
            child: SettingsListRow(
              icon: Icons.logout_rounded,
              iconColor: SettingsFlowPalette.error,
              title: 'Sign out',
              subtitle: 'End this session on the current device',
              destructive: true,
              onTap: () => showLogoutConfirmationSheet(context),
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

class _HeroOrb extends StatelessWidget {
  final double size;
  final Color color;

  const _HeroOrb({required this.size, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
    );
  }
}

class _ThemeSettingsSection extends StatelessWidget {
  const _ThemeSettingsSection();

  @override
  Widget build(BuildContext context) {
    return const Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SettingsSectionHeading(
          title: 'Theme',
          subtitle:
              'Match your device, keep things light, or switch into FutureGate dark mode.',
        ),
        SizedBox(height: 10),
        _ThemeSettingsPanel(),
      ],
    );
  }
}

class _ThemeSettingsPanel extends StatelessWidget {
  const _ThemeSettingsPanel();

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<ThemeController>();

    return SettingsPanel(
      padding: const EdgeInsets.all(10),
      child: Column(
        children: [
          for (final option in AppThemePreference.values) ...[
            _ThemeOptionTile(
              option: option,
              selected: controller.preference == option,
              onTap: () {
                controller.setPreference(option);
              },
            ),
            if (option != AppThemePreference.values.last)
              const SizedBox(height: 8),
          ],
        ],
      ),
    );
  }
}

class _ThemeOptionTile extends StatelessWidget {
  final AppThemePreference option;
  final bool selected;
  final VoidCallback onTap;

  const _ThemeOptionTile({
    required this.option,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final accent = switch (option) {
      AppThemePreference.system => SettingsFlowPalette.secondary,
      AppThemePreference.light => SettingsFlowPalette.accent,
      AppThemePreference.dark => SettingsFlowPalette.primary,
    };
    final icon = switch (option) {
      AppThemePreference.system => Icons.brightness_auto_rounded,
      AppThemePreference.light => Icons.light_mode_outlined,
      AppThemePreference.dark => Icons.dark_mode_outlined,
    };

    return InkWell(
      onTap: onTap,
      borderRadius: SettingsFlowTheme.radius(18),
      child: Ink(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
        decoration: BoxDecoration(
          color: selected
              ? accent.withValues(alpha: 0.13)
              : SettingsFlowPalette.surface,
          borderRadius: SettingsFlowTheme.radius(18),
          border: Border.all(
            color: selected
                ? accent.withValues(alpha: 0.30)
                : SettingsFlowPalette.border,
          ),
        ),
        child: Row(
          children: [
            SettingsIconBox(icon: icon, color: accent),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    option.title,
                    style: SettingsFlowTheme.cardTitle(
                      selected ? accent : SettingsFlowPalette.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(option.subtitle, style: SettingsFlowTheme.caption()),
                ],
              ),
            ),
            const SizedBox(width: 8),
            AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                color: selected ? accent : Colors.transparent,
                shape: BoxShape.circle,
                border: Border.all(
                  color: selected ? accent : SettingsFlowPalette.border,
                  width: 1.6,
                ),
              ),
              child: selected
                  ? const Icon(
                      Icons.check_rounded,
                      color: Colors.white,
                      size: 16,
                    )
                  : null,
            ),
          ],
        ),
      ),
    );
  }
}
