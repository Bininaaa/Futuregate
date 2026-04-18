import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../l10n/generated/app_localizations.dart';
import '../../providers/auth_provider.dart';
import 'account_security_screens.dart';
import 'settings_flow_theme.dart';
import 'settings_flow_widgets.dart';

class SecurityPrivacyScreen extends StatelessWidget {
  const SecurityPrivacyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final authProvider = context.watch<AuthProvider>();
    final user = authProvider.userModel;
    final hasGoogleProvider = authProvider.hasGoogleProvider;
    final hasPasswordProvider = authProvider.hasPasswordProvider;
    final canAddPassword = authProvider.canAddPassword;
    final canChangePassword = authProvider.canChangePassword;
    final canChangeEmail = authProvider.canChangeEmail;
    final providerLabel = authProvider.linkedProviderLabel;

    return SettingsPageScaffold(
      title: l10n.securityPrivacyTitle,
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
                    l10n.accountProtectionHubTitle,
                    style: SettingsFlowTheme.sectionTitle(),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    l10n.accountProtectionHubBody,
                    style: SettingsFlowTheme.caption(),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 18),
          SettingsSectionHeading(
            title: l10n.accountSecuritySectionTitle,
            subtitle: l10n.accountSecuritySectionSubtitle,
          ),
          const SizedBox(height: 10),
          SettingsPanel(
            child: Column(
              children: [
                if (canAddPassword) ...[
                  SettingsListRow(
                    icon: Icons.password_rounded,
                    iconColor: SettingsFlowPalette.primary,
                    title: l10n.addPasswordTitle,
                    subtitle: l10n.addPasswordSubtitle,
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
                    title: l10n.changePasswordTitle,
                    subtitle: l10n.changePasswordSubtitle,
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
                    title: l10n.changeEmailTitle,
                    subtitle: user?.email.isNotEmpty == true
                        ? l10n.changeEmailCurrentSubtitle(user!.email)
                        : l10n.changeEmailVerifySubtitle,
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
                        ? l10n.googleLinkedAccountTitle
                        : l10n.googleManagedAccountTitle,
                    message: hasPasswordProvider
                        ? l10n.googleLinkedAccountBody
                        : l10n.googleManagedAccountBody,
                    color: SettingsFlowPalette.secondary,
                  ),
                  const SizedBox(height: 10),
                ],
                SettingsListRow(
                  icon: Icons.verified_user_outlined,
                  iconColor: SettingsFlowPalette.success,
                  title: l10n.twoStepVerificationTitle,
                  subtitle: hasGoogleProvider
                      ? l10n.twoStepVerificationGoogleSubtitle
                      : l10n.twoStepVerificationEmailSubtitle,
                  onTap: () => _showDetailsSheet(
                    context,
                    title: l10n.twoStepVerificationTitle,
                    icon: Icons.verified_user_outlined,
                    message: hasGoogleProvider
                        ? l10n.twoStepVerificationGoogleBody(providerLabel)
                        : l10n.twoStepVerificationEmailBody,
                  ),
                ),
                const SizedBox(height: 10),
                SettingsListRow(
                  icon: Icons.devices_rounded,
                  iconColor: SettingsFlowPalette.accent,
                  title: l10n.manageSessionsTitle,
                  subtitle: l10n.manageSessionsSubtitle,
                  onTap: () => _showDetailsSheet(
                    context,
                    title: l10n.sessionsDevicesTitle,
                    icon: Icons.devices_rounded,
                    message: l10n.sessionsDevicesBody,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          SettingsSectionHeading(
            title: l10n.privacyControlsSectionTitle,
            subtitle: l10n.privacyControlsSectionSubtitle,
          ),
          const SizedBox(height: 10),
          SettingsPanel(
            child: Column(
              children: [
                SettingsListRow(
                  icon: Icons.tune_rounded,
                  iconColor: SettingsFlowPalette.primaryDark,
                  title: l10n.dataPermissionsTitle,
                  subtitle: l10n.dataPermissionsSubtitle,
                  onTap: () => _showDetailsSheet(
                    context,
                    title: l10n.dataPermissionsTitle,
                    icon: Icons.tune_rounded,
                    message: l10n.dataPermissionsBody,
                  ),
                ),
                const SizedBox(height: 10),
                SettingsListRow(
                  icon: Icons.privacy_tip_outlined,
                  iconColor: SettingsFlowPalette.secondary,
                  title: l10n.privacyPolicySettingsTitle,
                  subtitle: l10n.privacyPolicySettingsSubtitle,
                  onTap: () => _showDetailsSheet(
                    context,
                    title: l10n.privacyPolicySettingsTitle,
                    icon: Icons.privacy_tip_outlined,
                    message: l10n.privacyPolicySettingsBody,
                  ),
                ),
                const SizedBox(height: 10),
                SettingsListRow(
                  icon: Icons.gavel_rounded,
                  iconColor: SettingsFlowPalette.warning,
                  title: l10n.termsOfUseSettingsTitle,
                  subtitle: l10n.termsOfUseSettingsSubtitle,
                  onTap: () => _showDetailsSheet(
                    context,
                    title: l10n.termsOfUseSettingsTitle,
                    icon: Icons.gavel_rounded,
                    message: l10n.termsOfUseSettingsBody,
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
