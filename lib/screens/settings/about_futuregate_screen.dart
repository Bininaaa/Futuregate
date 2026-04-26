import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../config/app_metadata.dart';
import '../../l10n/generated/app_localizations.dart';
import '../../widgets/shared/app_feedback.dart';
import '../../widgets/shared/app_logo.dart';
import 'settings_flow_theme.dart';
import 'settings_flow_widgets.dart';

class AboutFutureGateScreen extends StatelessWidget {
  const AboutFutureGateScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return SettingsPageScaffold(
      title: l10n.aboutFutureGateTitle,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SettingsPanel(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SettingsAdaptiveHeader(
                  leading: Container(
                    decoration: BoxDecoration(
                      boxShadow: <BoxShadow>[
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.05),
                          blurRadius: 14,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: const AppLogoMark(
                      size: 76,
                      padding: 5,
                      borderRadius: BorderRadius.all(Radius.circular(22)),
                    ),
                  ),
                  content: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        AppMetadata.appName,
                        style: SettingsFlowTheme.heroTitle(),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        l10n.versionLabel(AppMetadata.version),
                        style: SettingsFlowTheme.caption(),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  AppMetadata.missionStatement,
                  style: SettingsFlowTheme.body(),
                ),
                const SizedBox(height: 12),
                Text(
                  l10n.aboutBridgeDescription,
                  style: SettingsFlowTheme.caption(),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          SettingsSectionHeading(
            title: l10n.platformStoryTitle,
            subtitle: l10n.platformStorySubtitle,
          ),
          const SizedBox(height: 10),
          SettingsPanel(
            child: Text(
              l10n.platformStoryBody,
              style: SettingsFlowTheme.caption(),
            ),
          ),
          const SizedBox(height: 18),
          SettingsSectionHeading(
            title: l10n.moreInformationTitle,
            subtitle: l10n.moreInformationSubtitle,
          ),
          const SizedBox(height: 10),
          SettingsPanel(
            child: Column(
              children: [
                SettingsListRow(
                  icon: Icons.gavel_rounded,
                  iconColor: SettingsFlowPalette.warning,
                  title: l10n.termsAboutTitle,
                  subtitle: l10n.termsAboutSubtitle,
                  onTap: () => _showInfoSheet(
                    context,
                    title: l10n.termsAboutTitle,
                    message: l10n.termsAboutBody,
                  ),
                ),
                const SizedBox(height: 10),
                SettingsListRow(
                  icon: Icons.privacy_tip_outlined,
                  iconColor: SettingsFlowPalette.secondary,
                  title: l10n.privacyPolicySettingsTitle,
                  subtitle: l10n.privacyPolicyAboutSubtitle,
                  onTap: () => _showInfoSheet(
                    context,
                    title: l10n.privacyPolicySettingsTitle,
                    message: l10n.privacyPolicyAboutBody,
                  ),
                ),
                const SizedBox(height: 10),
                SettingsListRow(
                  icon: Icons.mail_outline_rounded,
                  iconColor: SettingsFlowPalette.primary,
                  title: l10n.contactAboutTitle,
                  subtitle: AppMetadata.supportEmail,
                  onTap: () => _launchEmail(context),
                ),
                const SizedBox(height: 10),
                SettingsListRow(
                  icon: Icons.public_rounded,
                  iconColor: SettingsFlowPalette.primaryDark,
                  title: l10n.websiteSocialTitle,
                  subtitle: l10n.websiteSocialSubtitle,
                  onTap: () => _showInfoSheet(
                    context,
                    title: l10n.websiteSocialTitle,
                    message: l10n.websiteSocialBody,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _launchEmail(BuildContext context) async {
    final l10n = AppLocalizations.of(context)!;
    final uri = Uri(
      scheme: 'mailto',
      path: AppMetadata.supportEmail,
      queryParameters: {'subject': l10n.aboutFutureGateSubject},
    );

    final launched = await launchUrl(uri);
    if (!launched && context.mounted) {
      context.showAppSnackBar(
        l10n.noEmailAppAvailableAltBody,
        title: l10n.emailUnavailableWarningTitle,
        type: AppFeedbackType.warning,
      );
    }
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
