import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../config/app_metadata.dart';
import '../../l10n/generated/app_localizations.dart';
import '../../providers/auth_provider.dart';
import '../../services/app_intro_preferences_service.dart';
import '../../theme/theme_controller.dart';
import '../../widgets/shared/app_restart_scope.dart';
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
    final l10n = AppLocalizations.of(context)!;
    final authProvider = context.watch<AuthProvider>();
    final user = authProvider.userModel;

    if (user == null) {
      return Scaffold(body: Center(child: Text(l10n.notLoggedIn)));
    }

    final providerLabel = authProvider.linkedProviderLabel;
    final isCompany = user.role == 'company';
    final isAdmin = user.role == 'admin';

    if (isCompany) {
      return SettingsPageScaffold(
        title: l10n.uiWorkspace,
        embedded: embedded,
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
                    l10n.companyWorkspaceTitle,
                    style: SettingsFlowTheme.heroTitle(),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    l10n.companyWorkspaceBody,
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
                        label: l10n.versionLabel(AppMetadata.version),
                        color: SettingsFlowPalette.secondary,
                      ),
                      SettingsStatusPill(
                        label: (user.companyName ?? '').trim().isNotEmpty
                            ? (user.companyName ?? '').trim()
                            : l10n.companyAccountLabel,
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
            SettingsSectionHeading(
              title: l10n.securitySectionTitle,
              subtitle: l10n.securitySectionSubtitle,
            ),
            const SizedBox(height: 10),
            SettingsPanel(
              child: Column(
                children: [
                  SettingsListRow(
                    icon: Icons.lock_outline_rounded,
                    iconColor: SettingsFlowPalette.warning,
                    title: l10n.securityPrivacyTitle,
                    subtitle: l10n.securityPrivacySubtitle,
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
            SettingsSectionHeading(
              title: l10n.supportTitle,
              subtitle: l10n.supportSubtitle,
            ),
            const SizedBox(height: 10),
            SettingsPanel(
              child: Column(
                children: [
                  SettingsListRow(
                    icon: Icons.notifications_active_outlined,
                    iconColor: SettingsFlowPalette.secondary,
                    title: l10n.notificationsTitle,
                    subtitle: l10n.notificationsSubtitle,
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const NotificationsScreen(),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  SettingsListRow(
                    icon: Icons.help_outline_rounded,
                    iconColor: SettingsFlowPalette.secondary,
                    title: l10n.helpCenterTitle,
                    subtitle: l10n.helpCenterSubtitle,
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
                    title: l10n.aboutFutureGateTitle,
                    subtitle: l10n.aboutFutureGateSubtitle,
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
                    title: l10n.appVersionTitle,
                    subtitle: AppMetadata.version,
                    trailing: SettingsStatusPill(
                      label: l10n.appVersionCurrentLabel,
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
                title: l10n.signOutTitle,
                subtitle: l10n.signOutCompanySubtitle,
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
          : l10n.adminAccountLabel;

      return SettingsPageScaffold(
        title: l10n.adminSettingsTitle,
        embedded: embedded,
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
                    l10n.adminWorkspaceBody,
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
                        label: adminLevel.isEmpty ? l10n.adminLabel : adminLevel,
                        color: SettingsFlowPalette.secondary,
                      ),
                      SettingsStatusPill(
                        label: l10n.versionLabel(AppMetadata.version),
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
            SettingsSectionHeading(
              title: l10n.workspaceTitle,
              subtitle: l10n.adminWorkspaceSectionSubtitle,
            ),
            const SizedBox(height: 10),
            SettingsPanel(
              child: Column(
                children: [
                  SettingsListRow(
                    icon: Icons.notifications_active_outlined,
                    iconColor: SettingsFlowPalette.secondary,
                    title: l10n.notificationsTitle,
                    subtitle: l10n.notificationsSubtitle,
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
                    title: l10n.securityPrivacyTitle,
                    subtitle: l10n.securityPrivacySubtitle,
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
            SettingsSectionHeading(
              title: l10n.supportTitle,
              subtitle: l10n.adminSupportSubtitle,
            ),
            const SizedBox(height: 10),
            SettingsPanel(
              child: Column(
                children: [
                  SettingsListRow(
                    icon: Icons.help_outline_rounded,
                    iconColor: SettingsFlowPalette.secondary,
                    title: l10n.helpCenterTitle,
                    subtitle: l10n.helpCenterSubtitle,
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
                    title: l10n.aboutFutureGateTitle,
                    subtitle: l10n.aboutFutureGateSubtitle,
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
                    title: l10n.appVersionTitle,
                    subtitle: AppMetadata.version,
                    trailing: SettingsStatusPill(
                      label: l10n.appVersionCurrentLabel,
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
                title: l10n.signOutTitle,
                subtitle: l10n.signOutAdminSubtitle,
                destructive: true,
                onTap: () => showLogoutConfirmationSheet(context),
              ),
            ),
          ],
        ),
      );
    }

    return SettingsPageScaffold(
      title: l10n.settingsTitle,
      embedded: embedded,
      showAppBar: !embedded,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SettingsPanel(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(l10n.preferencesTitle, style: SettingsFlowTheme.heroTitle()),
                const SizedBox(height: 8),
                Text(
                  l10n.preferencesSubtitle,
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
                      label: l10n.versionLabel(AppMetadata.version),
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
          SettingsSectionHeading(
            title: l10n.experienceTitle,
            subtitle: l10n.experienceSubtitle,
          ),
          const SizedBox(height: 10),
          SettingsPanel(
            child: Column(
              children: [
                SettingsListRow(
                  icon: Icons.language_rounded,
                  iconColor: SettingsFlowPalette.secondary,
                  title: l10n.languageTitle,
                  subtitle: l10n.languageEnglish,
                  onTap: () => _showInfoSheet(
                    context,
                    title: l10n.languageTitle,
                    message: l10n.languageInfoSheetMessage,
                  ),
                ),
                const SizedBox(height: 10),
                SettingsListRow(
                  icon: Icons.notifications_active_outlined,
                  iconColor: SettingsFlowPalette.accent,
                  title: l10n.notificationPreferencesTitle,
                  subtitle: l10n.notificationPreferencesSubtitle,
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
          SettingsSectionHeading(
            title: l10n.accountTitle,
            subtitle: l10n.accountSubtitle,
          ),
          const SizedBox(height: 10),
          SettingsPanel(
            child: Column(
              children: [
                SettingsListRow(
                  icon: Icons.person_outline_rounded,
                  iconColor: SettingsFlowPalette.primaryDark,
                  title: l10n.accountPreferencesTitle,
                  subtitle: l10n.accountPreferencesSubtitle,
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
                  title: l10n.securityPrivacyTitle,
                  subtitle: l10n.securityPrivacySubtitle,
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
                  title: l10n.appVersionTitle,
                  subtitle: AppMetadata.version,
                  trailing: SettingsStatusPill(
                    label: l10n.appVersionCurrentLabel,
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
              title: l10n.signOutTitle,
              subtitle: l10n.signOutSubtitle,
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
    final l10n = AppLocalizations.of(context)!;
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
                  label: l10n.closeLabel,
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
    final l10n = AppLocalizations.of(context)!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SettingsSectionHeading(title: l10n.themeTitle),
        const SizedBox(height: 8),
        const _ThemeSettingsPanel(),
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
      final l10n = AppLocalizations.of(context)!;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.startupAnimErrorMessage),
        ),
      );
      return;
    }

    if (!mounted) return;
    setState(() => _isSaving = false);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final disabled = _isLoading || _isSaving;
    final subtitle = _isLoading
        ? l10n.startupAnimCheckingSubtitle
        : _showStartupAnimation
        ? l10n.startupAnimOnSubtitle
        : l10n.startupAnimOffSubtitle;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SettingsSectionHeading(title: l10n.startSectionTitle),
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
            title: l10n.showStartupAnimationTitle,
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
    final l10n = AppLocalizations.of(context)!;
    final controller = context.watch<ThemeController>();
    final selected = controller.preference;
    final accent = _themeAccent(selected);

    return SettingsPanel(
      padding: const EdgeInsets.all(8),
      child: _CompactPreferenceRow(
        icon: _themeIcon(selected),
        iconColor: accent,
        title: l10n.appThemeTitle,
        subtitle: _themeSubtitle(selected, l10n),
        trailing: _ThemeInlineSelect(
          selected: selected,
          onChanged: (option) async {
            final wasDark = _isEffectiveDarkTheme(selected);
            final willBeDark = _isEffectiveDarkTheme(option);

            await controller.setPreference(option);
            if (!context.mounted || wasDark || !willBeDark) {
              return;
            }

            AppRestartScope.restart(context);
          },
        ),
      ),
    );
  }
}

class _ThemeInlineSelect extends StatelessWidget {
  final AppThemePreference selected;
  final Future<void> Function(AppThemePreference option) onChanged;

  const _ThemeInlineSelect({required this.selected, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
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
                    _themeSelectLabel(option, l10n),
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
                        _themeSelectLabel(option, l10n),
                        style: SettingsFlowTheme.body(),
                      ),
                    ],
                  ),
                ),
              )
              .toList(growable: false),
          onChanged: (option) async {
            if (option != null) {
              await onChanged(option);
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

String _themeSelectLabel(AppThemePreference option, AppLocalizations l10n) {
  return switch (option) {
    AppThemePreference.system => l10n.themeSystemLabel,
    AppThemePreference.light => l10n.themeLightLabel,
    AppThemePreference.dark => l10n.themeDarkLabel,
  };
}

String _themeSubtitle(AppThemePreference option, AppLocalizations l10n) {
  return switch (option) {
    AppThemePreference.system => l10n.themeSystemSubtitle,
    AppThemePreference.light => l10n.themeLightSubtitle,
    AppThemePreference.dark => l10n.themeDarkSubtitle,
  };
}

bool _isEffectiveDarkTheme(AppThemePreference option) {
  return switch (option) {
    AppThemePreference.system =>
      WidgetsBinding.instance.platformDispatcher.platformBrightness ==
          Brightness.dark,
    AppThemePreference.light => false,
    AppThemePreference.dark => true,
  };
}
