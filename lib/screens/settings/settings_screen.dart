import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../config/app_metadata.dart';
import '../../providers/auth_provider.dart';
import '../../services/app_intro_preferences_service.dart';
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
  final bool embedded;

  const SettingsScreen({super.key, this.embedded = false});

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final user = authProvider.userModel;

    if (user == null) {
      return const Scaffold(body: Center(child: Text('Not logged in')));
    }

    final providerLabel = authProvider.linkedProviderLabel;
    final isCompany = user.role == 'company';
    final isAdmin = user.role == 'admin';

    if (isCompany) {
      return SettingsPageScaffold(
        title: 'More',
        showAppBar: !embedded,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SettingsPanel(
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Company workspace',
                    style: SettingsFlowTheme.heroTitle(),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Keep your public presence, theme, security, and support paths in one tidy place.',
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
                      SettingsStatusPill(
                        label: (user.companyName ?? '').trim().isNotEmpty
                            ? (user.companyName ?? '').trim()
                            : 'Company account',
                        color: SettingsFlowPalette.accent,
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),
            const _ThemeSettingsSection(),
            const SizedBox(height: 12),
            const _LaunchAnimationSettingsSection(),
            const SizedBox(height: 16),
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
                    subtitle:
                        'Preview your public profile and make edits there',
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const CompanyProfileScreen(),
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

    if (isAdmin) {
      final adminLevel = (user.adminLevel ?? '').trim();
      final displayName = user.fullName.trim().isNotEmpty
          ? user.fullName.trim()
          : 'Admin account';

      return SettingsPageScaffold(
        title: 'Admin Settings',
        showAppBar: !embedded,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SettingsPanel(
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(displayName, style: SettingsFlowTheme.heroTitle()),
                  const SizedBox(height: 8),
                  Text(
                    'Control your workspace preferences without changing the admin profile record.',
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
                        label: adminLevel.isEmpty ? 'Admin' : adminLevel,
                        color: SettingsFlowPalette.secondary,
                      ),
                      SettingsStatusPill(
                        label: 'Version ${AppMetadata.version}',
                        color: SettingsFlowPalette.accent,
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),
            const _ThemeSettingsSection(),
            const SizedBox(height: 12),
            const _LaunchAnimationSettingsSection(),
            const SizedBox(height: 16),
            const SettingsSectionHeading(
              title: 'Workspace',
              subtitle:
                  'Keep platform operations close without exposing profile editing.',
            ),
            const SizedBox(height: 10),
            SettingsPanel(
              child: Column(
                children: [
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
              subtitle: 'App information and help for platform admins.',
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
                subtitle: 'End this admin session on the current device',
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
      showAppBar: !embedded,
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
          const _ThemeSettingsSection(),
          const SizedBox(height: 12),
          const _LaunchAnimationSettingsSection(),
          const SizedBox(height: 16),
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

class _ThemeSettingsSection extends StatelessWidget {
  const _ThemeSettingsSection();

  @override
  Widget build(BuildContext context) {
    return const Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SettingsSectionHeading(title: 'Theme'),
        SizedBox(height: 8),
        _ThemeSettingsPanel(),
      ],
    );
  }
}

class _CompactPreferenceRow extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;
  final Widget trailing;
  final VoidCallback? onTap;

  const _CompactPreferenceRow({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    required this.trailing,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: SettingsFlowTheme.radius(16),
      child: Ink(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
        decoration: BoxDecoration(
          color: SettingsFlowPalette.surface,
          borderRadius: SettingsFlowTheme.radius(16),
          border: Border.all(color: SettingsFlowPalette.border),
        ),
        child: Row(
          children: [
            Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                color: iconColor.withValues(alpha: 0.12),
                borderRadius: SettingsFlowTheme.radius(12),
              ),
              child: Icon(icon, color: iconColor, size: 17),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: SettingsFlowTheme.cardTitle(),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: SettingsFlowTheme.caption(),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            trailing,
          ],
        ),
      ),
    );
  }
}

class _LaunchAnimationSettingsSection extends StatefulWidget {
  const _LaunchAnimationSettingsSection();

  @override
  State<_LaunchAnimationSettingsSection> createState() =>
      _LaunchAnimationSettingsSectionState();
}

class _LaunchAnimationSettingsSectionState
    extends State<_LaunchAnimationSettingsSection> {
  final AppIntroPreferencesService _introPreferencesService =
      AppIntroPreferencesService();

  bool _isLoading = true;
  bool _isSaving = false;
  bool _showStartupAnimation = true;

  @override
  void initState() {
    super.initState();
    _loadPreference();
  }

  Future<void> _loadPreference() async {
    final skipAnimation = await _introPreferencesService
        .shouldSkipLaunchAnimation();
    if (!mounted) return;

    setState(() {
      _showStartupAnimation = !skipAnimation;
      _isLoading = false;
    });
  }

  Future<void> _setShowStartupAnimation(bool showAnimation) async {
    if (_isLoading || _isSaving || showAnimation == _showStartupAnimation) {
      return;
    }

    final previousValue = _showStartupAnimation;
    setState(() {
      _showStartupAnimation = showAnimation;
      _isSaving = true;
    });

    try {
      await _introPreferencesService.setSkipLaunchAnimation(!showAnimation);
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _showStartupAnimation = previousValue;
        _isSaving = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Could not update the startup animation setting.'),
        ),
      );
      return;
    }

    if (!mounted) return;
    setState(() => _isSaving = false);
  }

  @override
  Widget build(BuildContext context) {
    final disabled = _isLoading || _isSaving;
    final subtitle = _isLoading
        ? 'Checking your launch preference...'
        : _showStartupAnimation
        ? 'The launch video will play when FutureGate opens.'
        : 'FutureGate will open directly next time.';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SettingsSectionHeading(title: 'Start'),
        const SizedBox(height: 8),
        SettingsPanel(
          padding: const EdgeInsets.all(8),
          child: _CompactPreferenceRow(
            icon: _showStartupAnimation
                ? Icons.movie_filter_outlined
                : Icons.motion_photos_off_outlined,
            iconColor: _showStartupAnimation
                ? SettingsFlowPalette.accent
                : SettingsFlowPalette.textSecondary,
            title: 'Show startup animation',
            subtitle: subtitle,
            onTap: disabled
                ? null
                : () => _setShowStartupAnimation(!_showStartupAnimation),
            trailing: SizedBox(
              width: 44,
              height: 28,
              child: FittedBox(
                fit: BoxFit.contain,
                child: Switch.adaptive(
                  key: const ValueKey<String>('startup_animation_switch'),
                  value: _showStartupAnimation,
                  activeThumbColor: SettingsFlowPalette.primary,
                  activeTrackColor: SettingsFlowPalette.primary.withValues(
                    alpha: 0.34,
                  ),
                  onChanged: disabled ? null : _setShowStartupAnimation,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _ThemeSettingsPanel extends StatelessWidget {
  const _ThemeSettingsPanel();

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<ThemeController>();
    final selected = controller.preference;
    final accent = _themeAccent(selected);

    return SettingsPanel(
      padding: const EdgeInsets.all(8),
      child: _CompactPreferenceRow(
        icon: _themeIcon(selected),
        iconColor: accent,
        title: 'App theme',
        subtitle: selected.subtitle,
        trailing: _ThemeInlineSelect(
          selected: selected,
          onChanged: (option) => controller.setPreference(option),
        ),
      ),
    );
  }
}

class _ThemeInlineSelect extends StatelessWidget {
  final AppThemePreference selected;
  final ValueChanged<AppThemePreference> onChanged;

  const _ThemeInlineSelect({required this.selected, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final accent = _themeAccent(selected);

    return Container(
      constraints: const BoxConstraints(minWidth: 104, maxWidth: 132),
      padding: const EdgeInsetsDirectional.only(start: 10, end: 4),
      decoration: BoxDecoration(
        color: accent.withValues(alpha: 0.12),
        borderRadius: SettingsFlowTheme.radius(999),
        border: Border.all(color: accent.withValues(alpha: 0.24)),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<AppThemePreference>(
          value: selected,
          isDense: true,
          borderRadius: SettingsFlowTheme.radius(14),
          dropdownColor: SettingsFlowPalette.surface,
          icon: Icon(
            Icons.keyboard_arrow_down_rounded,
            color: accent,
            size: 18,
          ),
          selectedItemBuilder: (context) => AppThemePreference.values
              .map(
                (option) => Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    _themeSelectLabel(option),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: SettingsFlowTheme.micro(accent),
                  ),
                ),
              )
              .toList(growable: false),
          items: AppThemePreference.values
              .map(
                (option) => DropdownMenuItem<AppThemePreference>(
                  value: option,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        _themeIcon(option),
                        color: _themeAccent(option),
                        size: 16,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        _themeSelectLabel(option),
                        style: SettingsFlowTheme.body(),
                      ),
                    ],
                  ),
                ),
              )
              .toList(growable: false),
          onChanged: (option) {
            if (option != null) {
              onChanged(option);
            }
          },
        ),
      ),
    );
  }
}

Color _themeAccent(AppThemePreference option) {
  return switch (option) {
    AppThemePreference.system => SettingsFlowPalette.secondary,
    AppThemePreference.light => SettingsFlowPalette.accent,
    AppThemePreference.dark => SettingsFlowPalette.primary,
  };
}

IconData _themeIcon(AppThemePreference option) {
  return switch (option) {
    AppThemePreference.system => Icons.brightness_auto_rounded,
    AppThemePreference.light => Icons.light_mode_outlined,
    AppThemePreference.dark => Icons.dark_mode_outlined,
  };
}

String _themeSelectLabel(AppThemePreference option) {
  return switch (option) {
    AppThemePreference.system => 'System',
    AppThemePreference.light => 'Light',
    AppThemePreference.dark => 'Dark',
  };
}
