import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../config/app_metadata.dart';
import '../../widgets/shared/app_feedback.dart';
import 'settings_flow_theme.dart';
import 'settings_flow_widgets.dart';

class AboutAvenirDzScreen extends StatelessWidget {
  const AboutAvenirDzScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return SettingsPageScaffold(
      title: 'About AvenirDZ',
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
                    width: 64,
                    height: 64,
                    decoration: BoxDecoration(
                      gradient: SettingsFlowPalette.primaryGradient,
                      borderRadius: SettingsFlowTheme.radius(22),
                    ),
                    child: Center(
                      child: Text(
                        'A',
                        style: SettingsFlowTheme.heroTitle(
                          Colors.white,
                        ).copyWith(fontSize: 28),
                      ),
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
                        'Version ${AppMetadata.version}',
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
                  'AvenirDZ is designed as a bridge between students, their growing skills, and the real opportunities that can shape their next milestone.',
                  style: SettingsFlowTheme.caption(),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          const SettingsSectionHeading(
            title: 'Platform Story',
            subtitle:
                'A clearer path from student ambition to real-world opportunity.',
          ),
          const SizedBox(height: 10),
          SettingsPanel(
            child: Text(
              'The app brings together profiles, CV tools, opportunities, scholarships, project ideas, and communication so students can move from discovery to action in one place.',
              style: SettingsFlowTheme.caption(),
            ),
          ),
          const SizedBox(height: 18),
          const SettingsSectionHeading(
            title: 'More Information',
            subtitle: 'Useful references and contact points for the platform.',
          ),
          const SizedBox(height: 10),
          SettingsPanel(
            child: Column(
              children: [
                SettingsListRow(
                  icon: Icons.gavel_rounded,
                  iconColor: SettingsFlowPalette.warning,
                  title: 'Terms',
                  subtitle: 'Read the platform usage summary',
                  onTap: () => _showInfoSheet(
                    context,
                    title: 'Terms',
                    message:
                        'AvenirDZ expects accurate profiles, respectful communication, and responsible use of the application and content tools available in the app.',
                  ),
                ),
                const SizedBox(height: 10),
                SettingsListRow(
                  icon: Icons.privacy_tip_outlined,
                  iconColor: SettingsFlowPalette.secondary,
                  title: 'Privacy Policy',
                  subtitle: 'See how data supports the experience',
                  onTap: () => _showInfoSheet(
                    context,
                    title: 'Privacy Policy',
                    message:
                        'Profile, CV, notification, and application data are used only to provide the matching, review, and communication features that power the AvenirDZ experience.',
                  ),
                ),
                const SizedBox(height: 10),
                SettingsListRow(
                  icon: Icons.mail_outline_rounded,
                  iconColor: SettingsFlowPalette.primary,
                  title: 'Contact',
                  subtitle: AppMetadata.supportEmail,
                  onTap: () => _launchEmail(context),
                ),
                const SizedBox(height: 10),
                SettingsListRow(
                  icon: Icons.public_rounded,
                  iconColor: SettingsFlowPalette.primaryDark,
                  title: 'Website & Social',
                  subtitle: 'Public links are added here as they go live',
                  onTap: () => _showInfoSheet(
                    context,
                    title: 'Website & Social',
                    message:
                        'A public website and social channels are not linked inside this build yet. Support requests can still be sent directly by email.',
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
    final uri = Uri(
      scheme: 'mailto',
      path: AppMetadata.supportEmail,
      queryParameters: {'subject': 'About AvenirDZ'},
    );

    final launched = await launchUrl(uri);
    if (!launched && context.mounted) {
      context.showAppSnackBar(
        'No email app is available right now.',
        title: 'Email unavailable',
        type: AppFeedbackType.warning,
      );
    }
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
