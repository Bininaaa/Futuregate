import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../config/app_metadata.dart';
import '../../l10n/generated/app_localizations.dart';
import '../../widgets/shared/app_feedback.dart';
import 'settings_flow_theme.dart';
import 'settings_flow_widgets.dart';

class HelpCenterScreen extends StatefulWidget {
  const HelpCenterScreen({super.key});

  @override
  State<HelpCenterScreen> createState() => _HelpCenterScreenState();
}

class _HelpCenterScreenState extends State<HelpCenterScreen> {
  final TextEditingController _searchController = TextEditingController();

  List<_HelpTopic> _buildTopics(AppLocalizations l10n) {
    return [
      _HelpTopic(
        title: l10n.helpAccountHelpTitle,
        category: l10n.helpAccountCategory,
        description: l10n.helpAccountDescription,
        icon: Icons.person_outline_rounded,
      ),
      _HelpTopic(
        title: l10n.helpApplicationHelpTitle,
        category: l10n.helpApplicationCategory,
        description: l10n.helpApplicationDescription,
        icon: Icons.assignment_outlined,
      ),
      _HelpTopic(
        title: l10n.helpSavedItemsTitle,
        category: l10n.helpSavedItemsCategory,
        description: l10n.helpSavedItemsDescription,
        icon: Icons.bookmark_outline_rounded,
      ),
      _HelpTopic(
        title: l10n.helpCvBuilderTitle,
        category: l10n.helpCvBuilderCategory,
        description: l10n.helpCvBuilderDescription,
        icon: Icons.description_outlined,
      ),
      _HelpTopic(
        title: l10n.helpOpportunityPostingTitle,
        category: l10n.helpOpportunityCategory,
        description: l10n.helpOpportunityDescription,
        icon: Icons.campaign_outlined,
      ),
      _HelpTopic(
        title: l10n.notificationsTitle,
        category: l10n.helpNotificationsCategory,
        description: l10n.helpNotificationsDescription,
        icon: Icons.notifications_none_rounded,
      ),
    ];
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final topics = _buildTopics(l10n);
    final query = _searchController.text.trim().toLowerCase();
    final filteredTopics = topics
        .where(
          (topic) =>
              query.isEmpty ||
              topic.title.toLowerCase().contains(query) ||
              topic.category.toLowerCase().contains(query) ||
              topic.description.toLowerCase().contains(query),
        )
        .toList();

    return SettingsPageScaffold(
      title: l10n.helpCenterTitle,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SettingsPanel(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(l10n.howCanWeHelpTitle, style: SettingsFlowTheme.heroTitle()),
                const SizedBox(height: 8),
                Text(
                  l10n.howCanWeHelpSubtitle,
                  style: SettingsFlowTheme.caption(),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _searchController,
                  onChanged: (_) => setState(() {}),
                  style: SettingsFlowTheme.body(),
                  decoration: InputDecoration(
                    hintText: l10n.searchHelpTopicsHint,
                    hintStyle: SettingsFlowTheme.caption(),
                    prefixIcon: Icon(
                      Icons.search_rounded,
                      color: SettingsFlowPalette.textSecondary,
                    ),
                    filled: true,
                    fillColor: SettingsFlowPalette.background,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 14,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: SettingsFlowTheme.radius(20),
                      borderSide: BorderSide(color: SettingsFlowPalette.border),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: SettingsFlowTheme.radius(20),
                      borderSide: BorderSide(color: SettingsFlowPalette.border),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: SettingsFlowTheme.radius(20),
                      borderSide: BorderSide(
                        color: SettingsFlowPalette.primary,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 22),
          SettingsSectionHeading(
            title: l10n.quickSupportTitle,
            subtitle: l10n.quickSupportSubtitle,
          ),
          const SizedBox(height: 12),
          SettingsPanel(
            child: Column(
              children: [
                SettingsListRow(
                  icon: Icons.support_agent_outlined,
                  iconColor: SettingsFlowPalette.primary,
                  title: l10n.contactSupportTitle,
                  subtitle: AppMetadata.supportEmail,
                  onTap: () => _launchEmail(
                    context,
                    subject: l10n.supportRequestSubject,
                  ),
                ),
                const SizedBox(height: 10),
                SettingsListRow(
                  icon: Icons.report_problem_outlined,
                  iconColor: SettingsFlowPalette.accent,
                  title: l10n.reportProblemTitle,
                  subtitle: l10n.reportProblemSubtitle,
                  onTap: () =>
                      _launchEmail(context, subject: l10n.bugReportSubject),
                ),
              ],
            ),
          ),
          const SizedBox(height: 22),
          SettingsSectionHeading(
            title: l10n.faqsSectionTitle,
            subtitle: filteredTopics.isEmpty
                ? l10n.noTopicsMatchedSubtitle
                : l10n.helpTopicCount(filteredTopics.length),
          ),
          const SizedBox(height: 12),
          if (filteredTopics.isEmpty)
            SettingsEmptyState(
              icon: Icons.search_off_rounded,
              title: l10n.noHelpTopicsMatchTitle,
              message: l10n.noHelpTopicsMatchBody,
            )
          else
            ...filteredTopics.map(
              (topic) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: SettingsPanel(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      LayoutBuilder(
                        builder: (context, constraints) {
                          final compact = constraints.maxWidth < 320;

                          if (compact) {
                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    SettingsIconBox(
                                      icon: topic.icon,
                                      color: SettingsFlowPalette.primary,
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Text(
                                        topic.title,
                                        style: SettingsFlowTheme.cardTitle(),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 10),
                                SettingsStatusPill(
                                  label: topic.category,
                                  color: SettingsFlowPalette.secondary,
                                ),
                              ],
                            );
                          }

                          return Row(
                            children: [
                              SettingsIconBox(
                                icon: topic.icon,
                                color: SettingsFlowPalette.primary,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  topic.title,
                                  style: SettingsFlowTheme.cardTitle(),
                                ),
                              ),
                              SettingsStatusPill(
                                label: topic.category,
                                color: SettingsFlowPalette.secondary,
                              ),
                            ],
                          );
                        },
                      ),
                      const SizedBox(height: 12),
                      Text(
                        topic.description,
                        style: SettingsFlowTheme.caption(),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Future<void> _launchEmail(
    BuildContext context, {
    required String subject,
  }) async {
    final uri = Uri(
      scheme: 'mailto',
      path: AppMetadata.supportEmail,
      queryParameters: {'subject': subject},
    );

    final launched = await launchUrl(uri);
    if (!context.mounted) {
      return;
    }
    if (!launched) {
      final l10n = AppLocalizations.of(context)!;
      context.showAppSnackBar(
        l10n.noEmailAppAvailableBody,
        title: l10n.emailUnavailableWarningTitle,
        type: AppFeedbackType.warning,
      );
    }
  }
}

class _HelpTopic {
  final String title;
  final String category;
  final String description;
  final IconData icon;

  _HelpTopic({
    required this.title,
    required this.category,
    required this.description,
    required this.icon,
  });
}
