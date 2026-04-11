import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../config/app_metadata.dart';
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

  static const List<_HelpTopic> _topics = [
    _HelpTopic(
      title: 'Account Help',
      category: 'Account',
      description:
          'Update profile details, manage sign-in methods, and keep your student profile ready for new opportunities.',
      icon: Icons.person_outline_rounded,
    ),
    _HelpTopic(
      title: 'Application Help',
      category: 'Applications',
      description:
          'Track your submissions, review statuses, and understand what recruiters need to evaluate your profile.',
      icon: Icons.assignment_outlined,
    ),
    _HelpTopic(
      title: 'Saved Items',
      category: 'Dashboard',
      description:
          'Bookmark opportunities you want to revisit later and stay organized while you prepare applications.',
      icon: Icons.bookmark_outline_rounded,
    ),
    _HelpTopic(
      title: 'CV Builder',
      category: 'CV',
      description:
          'Create structured CV content, choose a template, preview your document, and export a PDF when you are ready.',
      icon: Icons.description_outlined,
    ),
    _HelpTopic(
      title: 'Opportunity Posting Help',
      category: 'Platform',
      description:
          'Learn how companies and approved listings appear inside the app so you can understand the platform flow end to end.',
      icon: Icons.campaign_outlined,
    ),
    _HelpTopic(
      title: 'Notifications',
      category: 'Updates',
      description:
          'Stay on top of application decisions, saved item changes, reminders, and platform alerts.',
      icon: Icons.notifications_none_rounded,
    ),
  ];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final query = _searchController.text.trim().toLowerCase();
    final filteredTopics = _topics
        .where(
          (topic) =>
              query.isEmpty ||
              topic.title.toLowerCase().contains(query) ||
              topic.category.toLowerCase().contains(query) ||
              topic.description.toLowerCase().contains(query),
        )
        .toList();

    return SettingsPageScaffold(
      title: 'Help Center',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SettingsPanel(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('How can we help?', style: SettingsFlowTheme.heroTitle()),
                const SizedBox(height: 8),
                Text(
                  'Search common topics, contact support, or report something that needs attention.',
                  style: SettingsFlowTheme.caption(),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _searchController,
                  onChanged: (_) => setState(() {}),
                  style: SettingsFlowTheme.body(),
                  decoration: InputDecoration(
                    hintText: 'Search help topics',
                    hintStyle: SettingsFlowTheme.caption(),
                    prefixIcon: const Icon(
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
                      borderSide: const BorderSide(
                        color: SettingsFlowPalette.border,
                      ),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: SettingsFlowTheme.radius(20),
                      borderSide: const BorderSide(
                        color: SettingsFlowPalette.border,
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: SettingsFlowTheme.radius(20),
                      borderSide: const BorderSide(
                        color: SettingsFlowPalette.primary,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 22),
          const SettingsSectionHeading(
            title: 'Quick Support',
            subtitle: 'Reach out with context so the team can help faster.',
          ),
          const SizedBox(height: 12),
          SettingsPanel(
            child: Column(
              children: [
                SettingsListRow(
                  icon: Icons.support_agent_outlined,
                  iconColor: SettingsFlowPalette.primary,
                  title: 'Contact Support',
                  subtitle: AppMetadata.supportEmail,
                  onTap: () => _launchEmail(
                    context,
                    subject: 'FutureGate Support Request',
                  ),
                ),
                const SizedBox(height: 10),
                SettingsListRow(
                  icon: Icons.report_problem_outlined,
                  iconColor: SettingsFlowPalette.accent,
                  title: 'Report a Problem',
                  subtitle: 'Share screenshots, steps, or account issues',
                  onTap: () =>
                      _launchEmail(context, subject: 'FutureGate Bug Report'),
                ),
              ],
            ),
          ),
          const SizedBox(height: 22),
          SettingsSectionHeading(
            title: 'FAQs',
            subtitle: filteredTopics.isEmpty
                ? 'No topics matched your search.'
                : '${filteredTopics.length} help topic${filteredTopics.length == 1 ? '' : 's'}',
          ),
          const SizedBox(height: 12),
          if (filteredTopics.isEmpty)
            const SettingsEmptyState(
              icon: Icons.search_off_rounded,
              title: 'No help topics match your search',
              message:
                  'Try a broader search term, or contact support if you need hands-on help.',
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
      context.showAppSnackBar(
        'No email app is available on this device.',
        title: 'Email unavailable',
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

  const _HelpTopic({
    required this.title,
    required this.category,
    required this.description,
    required this.icon,
  });
}
