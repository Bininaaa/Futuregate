import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../models/saved_scholarship_model.dart';
import '../../models/scholarship_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/saved_scholarship_provider.dart';
import '../../widgets/app_shell_background.dart';
import '../../widgets/shared/app_content_system.dart';
import '../../widgets/shared/app_feedback.dart';

class ScholarshipDetailScreen extends StatelessWidget {
  final ScholarshipModel scholarship;

  const ScholarshipDetailScreen({super.key, required this.scholarship});

  AppContentTheme get _theme => const AppContentTheme(
    accent: Color(0xFFEC4899),
    accentDark: Color(0xFFBE185D),
    accentSoft: Color(0xFFFCE7F3),
    secondary: Color(0xFF14B8A6),
    background: Color(0xFFFDF8FC),
    surface: Colors.white,
    surfaceMuted: Color(0xFFFDF2F8),
    border: Color(0xFFF3D7E6),
    textPrimary: Color(0xFF111827),
    textSecondary: Color(0xFF4B5563),
    textMuted: Color(0xFF6B7280),
    success: Color(0xFF16A34A),
    warning: Color(0xFFF59E0B),
    error: Color(0xFFEF4444),
    heroGradient: LinearGradient(
      colors: <Color>[Color(0xFFBE185D), Color(0xFFEC4899), Color(0xFFFB7185)],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    ),
  );

  String get _title {
    final value = scholarship.title.trim();
    return value.isEmpty ? 'Scholarship Opportunity' : value;
  }

  String get _provider {
    final value = scholarship.provider.trim();
    return value.isEmpty ? 'FutureGate Partner' : value;
  }

  String get _description {
    final value = scholarship.description.trim();
    return value.isEmpty ? 'A detailed overview is not available yet.' : value;
  }

  String get _eligibility {
    final value = scholarship.eligibility.trim();
    return value.isEmpty
        ? 'Eligibility details will be shared by the scholarship provider.'
        : value;
  }

  String get _deadlineText {
    final value = scholarship.deadline.trim();
    return value.isEmpty ? 'Provider-announced deadline' : value;
  }

  String get _amountText {
    final amount = scholarship.amount;
    if (amount <= 0) {
      return _fundingType ?? 'Funding shared on the official call';
    }

    final formatter = NumberFormat(
      amount is int || amount == amount.roundToDouble() ? '#,##0' : '#,##0.##',
    );
    return '${formatter.format(amount)} DA';
  }

  String? get _fundingType {
    final value = scholarship.fundingType?.trim();
    return value == null || value.isEmpty ? null : value;
  }

  String? get _level {
    final value = scholarship.level?.trim();
    return value == null || value.isEmpty ? null : value;
  }

  String? get _category {
    final value = scholarship.category?.trim();
    return value == null || value.isEmpty ? null : value;
  }

  String? get _locationText {
    final parts = <String>[];
    final city = scholarship.city?.trim();
    final country = scholarship.country?.trim();
    if (city != null && city.isNotEmpty) {
      parts.add(city);
    }
    if (country != null && country.isNotEmpty) {
      parts.add(country);
    }
    if (parts.isNotEmpty) {
      return parts.join(', ');
    }

    final location = scholarship.location?.trim();
    return location == null || location.isEmpty ? null : location;
  }

  Uri? get _linkUri {
    final rawLink = scholarship.link.trim();
    if (rawLink.isEmpty) {
      return null;
    }
    return Uri.tryParse(rawLink.contains('://') ? rawLink : 'https://$rawLink');
  }

  String? get _linkHost {
    final host = _linkUri?.host.trim();
    if (host == null || host.isEmpty) {
      return null;
    }
    return host.replaceFirst(RegExp(r'^www\.'), '');
  }

  List<String> get _eligibilityItems {
    final normalized = scholarship.eligibility.replaceAll('\r', '\n').trim();
    if (normalized.isEmpty) {
      return const <String>[];
    }

    final items = normalized
        .split(RegExp(r'\n+|;|\u2022'))
        .map((item) => item.replaceFirst(RegExp(r'^[-*]\s*'), '').trim())
        .where((item) => item.isNotEmpty)
        .toList(growable: false);
    return items.length > 1 ? items : const <String>[];
  }

  Future<void> _openLink(BuildContext context) async {
    final uri = _linkUri;
    if (uri == null) {
      context.showAppSnackBar(
        'This scholarship does not have an application link yet.',
        title: 'Link unavailable',
        type: AppFeedbackType.warning,
      );
      return;
    }

    final launched = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!launched && context.mounted) {
      context.showAppSnackBar(
        'We couldn\'t open the scholarship link right now.',
        title: 'Open unavailable',
        type: AppFeedbackType.error,
      );
    }
  }

  Future<void> _toggleSavedScholarship(BuildContext context) async {
    final userId = context.read<AuthProvider>().userModel?.uid.trim() ?? '';
    if (userId.isEmpty) {
      return;
    }

    final provider = context.read<SavedScholarshipProvider>();
    SavedScholarshipModel? existing;
    for (final item in provider.savedScholarships) {
      if (item.scholarshipId == scholarship.id) {
        existing = item;
        break;
      }
    }

    final error = existing != null
        ? await provider.unsaveScholarship(existing.id, userId)
        : await provider.saveScholarship(
            studentId: userId,
            scholarshipId: scholarship.id,
            title: _title,
            provider: _provider,
            deadline: _deadlineText,
            location: _locationText ?? 'Location not specified',
            fundingType: _fundingType ?? '',
            level: _level ?? '',
          );

    if (!context.mounted) {
      return;
    }

    context.showAppSnackBar(
      error ??
          (existing != null
              ? 'This scholarship was removed from your saved list.'
              : 'This scholarship has been saved.'),
      title: error == null ? 'Saved items updated' : 'Update unavailable',
      type: error == null ? AppFeedbackType.success : AppFeedbackType.error,
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>().userModel;
    final savedProvider = context.watch<SavedScholarshipProvider>();
    final currentUserId = auth?.uid.trim() ?? '';

    if (currentUserId.isNotEmpty &&
        !savedProvider.hasLoaded &&
        !savedProvider.isLoading) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!context.mounted) {
          return;
        }
        context.read<SavedScholarshipProvider>().fetchSavedScholarships(
          currentUserId,
        );
      });
    }

    SavedScholarshipModel? existingSaved;
    for (final item in savedProvider.savedScholarships) {
      if (item.scholarshipId == scholarship.id) {
        existingSaved = item;
        break;
      }
    }

    final hasLink = _linkUri != null;
    final isSaved = existingSaved != null;
    final badges = <AppBadgeData>[
      if (_fundingType != null) AppBadgeData(label: _fundingType!),
      if (_level != null)
        AppBadgeData(label: _level!, icon: Icons.school_outlined),
      if (_category != null)
        AppBadgeData(label: _category!, icon: Icons.category_outlined),
      if (scholarship.isFeatured)
        AppBadgeData(
          label: 'Featured',
          icon: Icons.workspace_premium_outlined,
          color: _theme.warning,
        ),
      ...scholarship.tags.take(3).map((tag) => AppBadgeData(label: tag)),
    ];

    return AppShellBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          foregroundColor: _theme.textPrimary,
          title: Text(
            'Scholarship',
            style: _theme.section(size: 18, weight: FontWeight.w700),
          ),
          actions: <Widget>[
            IconButton(
              tooltip: isSaved ? 'Unsave scholarship' : 'Save scholarship',
              onPressed: currentUserId.isEmpty || savedProvider.isLoading
                  ? null
                  : () => _toggleSavedScholarship(context),
              icon: Icon(
                isSaved
                    ? Icons.bookmark_rounded
                    : Icons.bookmark_outline_rounded,
              ),
            ),
            IconButton(
              tooltip: hasLink ? 'Open application link' : 'Link unavailable',
              onPressed: hasLink ? () => _openLink(context) : null,
              icon: Icon(
                hasLink ? Icons.open_in_new_rounded : Icons.link_off_rounded,
              ),
            ),
            const SizedBox(width: 6),
          ],
        ),
        bottomNavigationBar: SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: _theme.surface,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: _theme.border),
                boxShadow: _theme.shadow(0.04),
              ),
              child: Row(
                children: <Widget>[
                  Expanded(
                    child: AppSecondaryButton(
                      theme: _theme,
                      label: isSaved ? 'Saved' : 'Save',
                      icon: isSaved
                          ? Icons.bookmark_rounded
                          : Icons.bookmark_outline_rounded,
                      onPressed:
                          currentUserId.isEmpty || savedProvider.isLoading
                          ? null
                          : () => _toggleSavedScholarship(context),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: AppPrimaryButton(
                      theme: _theme,
                      label: hasLink ? 'Open Application' : 'Link Unavailable',
                      icon: hasLink
                          ? Icons.open_in_new_rounded
                          : Icons.link_off_rounded,
                      onPressed: hasLink ? () => _openLink(context) : null,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        body: ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 132),
          children: <Widget>[
            AppDetailHeroCard(
              theme: _theme,
              icon: Icons.card_giftcard_rounded,
              title: _title,
              subtitle: _provider,
              summary: _description,
              badges: badges,
              imageUrl: scholarship.imageUrl,
              footer: Column(
                children: <Widget>[
                  AppMetaRow(
                    theme: _theme,
                    label: 'Funding',
                    value: _amountText,
                    icon: Icons.payments_outlined,
                  ),
                  AppMetaRow(
                    theme: _theme,
                    label: 'Deadline',
                    value: _deadlineText,
                    icon: Icons.event_outlined,
                  ),
                  AppMetaRow(
                    theme: _theme,
                    label: 'Location',
                    value: _locationText ?? 'Location not specified',
                    icon: Icons.location_on_outlined,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            AppInfoTileGrid(
              theme: _theme,
              items: <AppInfoTileData>[
                AppInfoTileData(
                  label: 'Funding',
                  value: _amountText,
                  icon: Icons.payments_outlined,
                  emphasize: true,
                ),
                AppInfoTileData(
                  label: 'Deadline',
                  value: _deadlineText,
                  icon: Icons.event_available_rounded,
                ),
                AppInfoTileData(
                  label: 'Provider',
                  value: _provider,
                  icon: Icons.business_outlined,
                ),
                AppInfoTileData(
                  label: 'Destination',
                  value: _locationText ?? '',
                  icon: Icons.public_rounded,
                ),
                AppInfoTileData(
                  label: 'Level',
                  value: _level ?? '',
                  icon: Icons.school_outlined,
                ),
                AppInfoTileData(
                  label: 'Category',
                  value: _category ?? '',
                  icon: Icons.category_outlined,
                ),
              ],
            ),
            const SizedBox(height: 16),
            AppDetailSection(
              theme: _theme,
              title: 'Overview',
              icon: Icons.auto_awesome_rounded,
              child: Text(
                _description,
                style: _theme.body(color: _theme.textPrimary),
              ),
            ),
            const SizedBox(height: 16),
            AppDetailSection(
              theme: _theme,
              title: 'Eligibility',
              icon: Icons.verified_user_outlined,
              child: _eligibilityItems.isEmpty
                  ? Text(
                      _eligibility,
                      style: _theme.body(color: _theme.textPrimary),
                    )
                  : _ScholarshipBulletList(
                      theme: _theme,
                      items: _eligibilityItems,
                    ),
            ),
            const SizedBox(height: 16),
            AppDetailSection(
              theme: _theme,
              title: 'Scholarship Details',
              icon: Icons.fact_check_outlined,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  AppMetaRow(
                    theme: _theme,
                    label: 'Provider',
                    value: _provider,
                  ),
                  AppMetaRow(
                    theme: _theme,
                    label: 'Funding type',
                    value: _fundingType ?? '',
                  ),
                  AppMetaRow(
                    theme: _theme,
                    label: 'Level',
                    value: _level ?? '',
                  ),
                  AppMetaRow(
                    theme: _theme,
                    label: 'Category',
                    value: _category ?? '',
                  ),
                  AppMetaRow(
                    theme: _theme,
                    label: 'Country',
                    value: scholarship.country ?? '',
                  ),
                  AppMetaRow(
                    theme: _theme,
                    label: 'City',
                    value: scholarship.city ?? '',
                  ),
                  AppMetaRow(
                    theme: _theme,
                    label: 'Posted',
                    value: scholarship.createdAt == null
                        ? ''
                        : DateFormat(
                            'MMM d, yyyy',
                          ).format(scholarship.createdAt!.toDate()),
                  ),
                  AppMetaRow(
                    theme: _theme,
                    label: 'Created by role',
                    value: scholarship.createdByRole,
                  ),
                ],
              ),
            ),
            if (scholarship.tags.isNotEmpty) ...<Widget>[
              const SizedBox(height: 16),
              AppDetailSection(
                theme: _theme,
                title: 'Highlights',
                icon: Icons.local_offer_outlined,
                child: Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: scholarship.tags
                      .map(
                        (tag) => AppTagChip(
                          theme: _theme,
                          badge: AppBadgeData(label: tag),
                        ),
                      )
                      .toList(growable: false),
                ),
              ),
            ],
            const SizedBox(height: 16),
            AppDetailSection(
              theme: _theme,
              title: 'Application Access',
              icon: Icons.launch_rounded,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  AppMetaRow(
                    theme: _theme,
                    label: 'Official link',
                    value: scholarship.link.trim(),
                    icon: Icons.link_rounded,
                  ),
                  AppMetaRow(
                    theme: _theme,
                    label: 'Host',
                    value: _linkHost ?? '',
                    icon: Icons.language_rounded,
                  ),
                  if (!hasLink)
                    AppEmptyFieldPlaceholder(
                      theme: _theme,
                      text:
                          'An external application link is not available yet.',
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ScholarshipBulletList extends StatelessWidget {
  final AppContentTheme theme;
  final List<String> items;

  const _ScholarshipBulletList({required this.theme, required this.items});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: items
          .map((item) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Container(
                    width: 22,
                    height: 22,
                    margin: const EdgeInsets.only(top: 1),
                    decoration: BoxDecoration(
                      color: theme.accent.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      Icons.check_rounded,
                      size: 14,
                      color: theme.accent,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      item,
                      style: theme.body(color: theme.textPrimary),
                    ),
                  ),
                ],
              ),
            );
          })
          .toList(growable: false),
    );
  }
}
