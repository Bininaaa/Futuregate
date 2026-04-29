import 'package:flutter/material.dart';
import '../../l10n/generated/app_localizations.dart';
import '../../theme/app_typography.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../models/saved_scholarship_model.dart';
import '../../models/scholarship_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/opportunity_translation_provider.dart';
import '../../providers/saved_scholarship_provider.dart';
import '../../services/opportunity_translation_service.dart';
import '../../utils/document_launch_helper.dart';
import '../../utils/opportunity_dashboard_palette.dart';
import '../../widgets/app_shell_background.dart';
import '../../widgets/shared/app_directional.dart';
import '../../widgets/shared/app_feedback.dart';

typedef _P = OpportunityDashboardPalette;

class ScholarshipDetailScreen extends StatelessWidget {
  final ScholarshipModel scholarship;

  const ScholarshipDetailScreen({super.key, required this.scholarship});

  String _title(AppLocalizations l10n) {
    final value = scholarship.title.trim();
    return value.isEmpty ? l10n.scholarshipOpportunityFallback : value;
  }

  String _provider(AppLocalizations l10n) {
    final value = scholarship.provider.trim();
    return value.isEmpty ? l10n.scholarshipPartnerFallback : value;
  }

  String _description(AppLocalizations l10n) {
    final value = scholarship.description.trim();
    return value.isEmpty ? l10n.scholarshipNoDescFallback : value;
  }

  String _eligibility(AppLocalizations l10n) {
    final value = scholarship.eligibility.trim();
    return value.isEmpty ? l10n.scholarshipNoEligFallback : value;
  }

  String _deadlineText(AppLocalizations l10n) {
    final value = scholarship.deadline.trim();
    return value.isEmpty ? l10n.scholarshipDeadlineFallback : value;
  }

  String _amountText(AppLocalizations l10n) {
    final amount = scholarship.amount;
    if (amount <= 0) {
      final funding = _fundingType;
      return funding ?? l10n.scholarshipFundingFallback;
    }

    final isWholeNumber = amount is int || amount == amount.roundToDouble();
    final formatter = NumberFormat(isWholeNumber ? '#,##0' : '#,##0.##');
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
    if (city != null && city.isNotEmpty) {
      parts.add(city);
    }

    final country = scholarship.country?.trim();
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

    return DocumentLaunchHelper.normalizeHttpUri(rawLink);
  }

  String? get _linkHost {
    final host = _linkUri?.host.trim();
    if (host == null || host.isEmpty) {
      return null;
    }
    return host.replaceFirst(RegExp(r'^www\.'), '');
  }

  String get _primaryBadgeLabel {
    final funding = _fundingType;
    if (funding != null) {
      return funding.toUpperCase();
    }
    if (scholarship.isFeatured) {
      return 'FEATURED';
    }
    final level = _level;
    if (level != null) {
      return level.toUpperCase();
    }
    return 'SCHOLARSHIP';
  }

  String? get _secondaryBadgeLabel {
    if (_fundingType != null && scholarship.isFeatured) {
      return 'FEATURED';
    }
    return null;
  }

  List<String> get _heroChips {
    final chips = <String>[];

    void addChip(String? value) {
      final trimmed = value?.trim();
      if (trimmed == null || trimmed.isEmpty) {
        return;
      }

      final exists = chips.any(
        (chip) => chip.toLowerCase() == trimmed.toLowerCase(),
      );
      if (!exists) {
        chips.add(trimmed);
      }
    }

    addChip(_level);
    addChip(_category);

    for (final tag in scholarship.tags) {
      addChip(tag);
      if (chips.length >= 3) {
        break;
      }
    }

    return chips.take(3).toList(growable: false);
  }

  List<_ScholarshipStatData> _buildStats(AppLocalizations l10n) {
    final stats = <_ScholarshipStatData>[
      _ScholarshipStatData(
        icon: Icons.payments_rounded,
        label: scholarship.amount > 0
            ? l10n.scholarshipFundingAmount
            : l10n.scholarshipFundingDetails,
        value: _amountText(l10n),
        accentColor: _P.primary,
        highlight: true,
      ),
      _ScholarshipStatData(
        icon: Icons.event_available_rounded,
        label: l10n.uiDeadline,
        value: _deadlineText(l10n),
        accentColor: _P.accent,
      ),
    ];

    final location = _locationText;
    if (location != null) {
      stats.add(
        _ScholarshipStatData(
          icon: Icons.public_rounded,
          label: l10n.uiDestination,
          value: location,
          accentColor: _P.secondary,
        ),
      );
    } else {
      stats.add(
        _ScholarshipStatData(
          icon: Icons.apartment_rounded,
          label: l10n.uiProvider,
          value: _provider(l10n),
          accentColor: _P.secondary,
        ),
      );
    }

    final academicLabel = _level ?? _category;
    if (academicLabel != null) {
      stats.add(
        _ScholarshipStatData(
          icon: Icons.school_rounded,
          label: _level != null
              ? l10n.scholarshipStudyLevel
              : l10n.scholarshipProgramType,
          value: academicLabel,
          accentColor: _P.primaryDark,
        ),
      );
    } else if (_fundingType != null) {
      stats.add(
        _ScholarshipStatData(
          icon: Icons.workspace_premium_rounded,
          label: l10n.uiSupportType,
          value: _fundingType!,
          accentColor: _P.primaryDark,
        ),
      );
    }

    return stats;
  }

  List<_ScholarshipProfileRowData> _buildProfileRows(AppLocalizations l10n) {
    final rows = <_ScholarshipProfileRowData>[
      _ScholarshipProfileRowData(
        icon: Icons.business_center_rounded,
        label: l10n.uiProvider,
        value: _provider(l10n),
      ),
      _ScholarshipProfileRowData(
        icon: Icons.calendar_month_rounded,
        label: l10n.uiApplicationDeadline,
        value: _deadlineText(l10n),
      ),
    ];

    final location = _locationText;
    if (location != null) {
      rows.add(
        _ScholarshipProfileRowData(
          icon: Icons.location_on_outlined,
          label: l10n.uiLocation,
          value: location,
        ),
      );
    }

    if (_fundingType != null) {
      rows.add(
        _ScholarshipProfileRowData(
          icon: Icons.wallet_giftcard_rounded,
          label: l10n.uiFundingType,
          value: _fundingType!,
        ),
      );
    }

    if (_level != null) {
      rows.add(
        _ScholarshipProfileRowData(
          icon: Icons.auto_stories_rounded,
          label: l10n.uiLevel,
          value: _level!,
        ),
      );
    }

    if (_category != null) {
      rows.add(
        _ScholarshipProfileRowData(
          icon: Icons.category_rounded,
          label: l10n.uiCategory,
          value: _category!,
        ),
      );
    }

    return rows;
  }

  void _ensureTranslation(BuildContext context) {
    final originalLanguage = scholarship.originalLanguage.trim();
    if (originalLanguage.isEmpty) {
      return;
    }

    final currentLocale = Localizations.localeOf(context).languageCode;
    if (currentLocale == originalLanguage) {
      return;
    }

    final provider = context.read<OpportunityTranslationProvider>();
    final status = provider.statusForContent(
      contentType: ContentTranslationType.scholarship,
      contentId: scholarship.id,
    );
    if (status == TranslationStatus.loading ||
        status == TranslationStatus.ready) {
      return;
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!context.mounted) {
        return;
      }

      context.read<OpportunityTranslationProvider>().ensureContentTranslation(
        contentType: ContentTranslationType.scholarship,
        contentId: scholarship.id,
        fields: <String, String>{
          'title': scholarship.title,
          'description': scholarship.description,
          'eligibility': scholarship.eligibility,
        },
        currentLocale: currentLocale,
        originalLocale: originalLanguage,
      );
    });
  }

  List<String> _translatedEligibilityItems(String value) {
    final normalized = value.replaceAll('\r', '\n').trim();
    if (normalized.isEmpty) {
      return const <String>[];
    }

    final lineItems = normalized
        .split('\n')
        .map(
          (item) =>
              item.trim().replaceFirst(RegExp('^[-*\\u2022]\\s*'), '').trim(),
        )
        .where((item) => item.isNotEmpty)
        .toList(growable: false);

    if (lineItems.length > 1) {
      return lineItems.take(6).toList(growable: false);
    }

    final segmented = normalized
        .split(RegExp('[;\\u2022]'))
        .map((item) => item.trim())
        .where((item) => item.isNotEmpty)
        .toList(growable: false);

    if (segmented.length > 1) {
      return segmented.take(6).toList(growable: false);
    }

    return const <String>[];
  }

  Future<void> _openLink(BuildContext context) async {
    final uri = _linkUri;
    if (uri == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            AppLocalizations.of(context)!.noScholarshipLinkAvailable,
          ),
        ),
      );
      return;
    }

    await DocumentLaunchHelper.openUrl(
      context,
      url: uri.toString(),
      unavailableMessage: AppLocalizations.of(
        context,
      )!.couldNotOpenScholarshipLink,
      unavailableTitle: AppLocalizations.of(context)!.uiApplicationLink,
    );
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

    final l10n = AppLocalizations.of(context)!;
    final fallbackTitle = _title(l10n);
    final fallbackProvider = _provider(l10n);
    final fallbackDeadline = _deadlineText(l10n);
    final location = _locationText ?? l10n.uiLocation;

    final error = existing != null
        ? await provider.unsaveScholarship(existing.id, userId)
        : await provider.saveScholarship(
            studentId: userId,
            scholarshipId: scholarship.id,
            title: fallbackTitle,
            provider: fallbackProvider,
            deadline: fallbackDeadline,
            location: location,
            fundingType: _fundingType ?? '',
            level: _level ?? '',
          );

    if (!context.mounted) {
      return;
    }

    context.showAppSnackBar(
      error ??
          (existing != null
              ? l10n.scholarshipRemovedSavedMessage
              : l10n.scholarshipSavedMessage),
      title: error == null ? 'Saved items updated' : 'Update unavailable',
      type: error == null
          ? (existing != null
                ? AppFeedbackType.removed
                : AppFeedbackType.success)
          : AppFeedbackType.error,
      icon: error == null && existing != null
          ? Icons.bookmark_remove_outlined
          : null,
    );
  }

  @override
  Widget build(BuildContext context) {
    _ensureTranslation(context);
    final auth = context.watch<AuthProvider>().userModel;
    final translationProvider = context.watch<OpportunityTranslationProvider>();
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
    final isSaved = existingSaved != null;
    final hasLink = _linkUri != null;
    final location = _locationText;
    final l10n = AppLocalizations.of(context)!;
    final fallbackTitle = _title(l10n);
    final fallbackProvider = _provider(l10n);
    final fallbackDescription = _description(l10n);
    final fallbackEligibility = _eligibility(l10n);
    final fallbackDeadline = _deadlineText(l10n);
    final chips = _heroChips;
    final displayTitle =
        translationProvider
            .resolvedField(
              contentType: ContentTranslationType.scholarship,
              contentId: scholarship.id,
              field: 'title',
              originalValue: scholarship.title,
            )
            .trim()
            .isEmpty
        ? fallbackTitle
        : translationProvider.resolvedField(
            contentType: ContentTranslationType.scholarship,
            contentId: scholarship.id,
            field: 'title',
            originalValue: scholarship.title,
          );
    final displayDescription =
        translationProvider
            .resolvedField(
              contentType: ContentTranslationType.scholarship,
              contentId: scholarship.id,
              field: 'description',
              originalValue: scholarship.description,
            )
            .trim()
            .isEmpty
        ? fallbackDescription
        : translationProvider.resolvedField(
            contentType: ContentTranslationType.scholarship,
            contentId: scholarship.id,
            field: 'description',
            originalValue: scholarship.description,
          );
    final displayEligibility =
        translationProvider
            .resolvedField(
              contentType: ContentTranslationType.scholarship,
              contentId: scholarship.id,
              field: 'eligibility',
              originalValue: scholarship.eligibility,
            )
            .trim()
            .isEmpty
        ? fallbackEligibility
        : translationProvider.resolvedField(
            contentType: ContentTranslationType.scholarship,
            contentId: scholarship.id,
            field: 'eligibility',
            originalValue: scholarship.eligibility,
          );
    final eligibilityItems = _translatedEligibilityItems(displayEligibility);
    final profileRows = _buildProfileRows(l10n);

    return AppShellBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        bottomNavigationBar: SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
            child: _ScholarshipActionBar(
              hostLabel: _linkHost,
              enabled: hasLink,
              onTap: hasLink ? () => _openLink(context) : null,
            ),
          ),
        ),
        body: Stack(
          children: [
            Positioned(
              top: -72,
              right: -36,
              child: _SoftOrb(
                size: 184,
                color: _P.primary.withValues(alpha: 0.12),
              ),
            ),
            Positioned(
              top: 240,
              left: -58,
              child: _SoftOrb(
                size: 144,
                color: _P.secondary.withValues(alpha: 0.10),
              ),
            ),
            Column(
              children: [
                SafeArea(
                  bottom: false,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 10, 16, 6),
                    child: Row(
                      children: [
                        IconButton(
                          onPressed: () => Navigator.of(context).maybePop(),
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(
                            minWidth: 40,
                            minHeight: 40,
                          ),
                          icon: AppDirectionalIcon(
                            Icons.arrow_back_ios_new_rounded,
                            color: _P.textPrimary,
                            size: 24,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Scholarship',
                            textAlign: TextAlign.left,
                            style: AppTypography.product(
                              fontSize: 19,
                              fontWeight: FontWeight.w800,
                              color: _P.primary,
                            ),
                          ),
                        ),
                        _TopBarIconButton(
                          icon: isSaved
                              ? Icons.bookmark_rounded
                              : Icons.bookmark_outline_rounded,
                          onTap:
                              currentUserId.isEmpty || savedProvider.isLoading
                              ? null
                              : () => _toggleSavedScholarship(context),
                          iconColor: isSaved ? _P.primary : _P.textPrimary,
                          fillColor: isSaved
                              ? _P.primary.withValues(alpha: 0.08)
                              : _P.surface,
                        ),
                      ],
                    ),
                  ),
                ),
                Expanded(
                  child: ListView(
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 132),
                    children: [
                      _ScholarshipHeroCard(
                        scholarship: scholarship,
                        badgeLabel: _primaryBadgeLabel,
                        secondaryBadgeLabel: _secondaryBadgeLabel,
                        provider: fallbackProvider,
                        title: displayTitle,
                        location: location,
                        deadline: scholarship.deadline.trim().isEmpty
                            ? null
                            : fallbackDeadline,
                        chips: chips,
                      ),
                      const SizedBox(height: 22),
                      _PageSectionHeading(
                        eyebrow: l10n.scholarshipAtAGlance,
                        title: AppLocalizations.of(context)!.uiQuickSnapshot,
                        subtitle: l10n.scholarshipSnapshotSubtitle,
                      ),
                      const SizedBox(height: 14),
                      _ScholarshipStatsWrap(stats: _buildStats(l10n)),
                      const SizedBox(height: 22),
                      _ScholarshipSectionCard(
                        icon: Icons.auto_awesome_rounded,
                        iconColor: _P.primary,
                        title: AppLocalizations.of(
                          context,
                        )!.uiAboutThisScholarship,
                        subtitle: l10n.scholarshipOverviewSubtitle,
                        child: Text(
                          displayDescription,
                          style: AppTypography.product(
                            fontSize: 13,
                            height: 1.7,
                            color: _P.textSecondary,
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      _ScholarshipSectionCard(
                        icon: Icons.verified_user_rounded,
                        iconColor: _P.secondary,
                        title: AppLocalizations.of(context)!.uiWhoCanApply,
                        subtitle: AppLocalizations.of(
                          context,
                        )!.uiCheckTheCoreEligibilitySignalsBeforeMovingForward,
                        child: eligibilityItems.isEmpty
                            ? Text(
                                displayEligibility,
                                style: AppTypography.product(
                                  fontSize: 13,
                                  height: 1.7,
                                  color: _P.textSecondary,
                                ),
                              )
                            : Column(
                                children: eligibilityItems
                                    .asMap()
                                    .entries
                                    .map(
                                      (entry) => Padding(
                                        padding: EdgeInsets.only(
                                          bottom:
                                              entry.key ==
                                                  eligibilityItems.length - 1
                                              ? 0
                                              : 10,
                                        ),
                                        child: _EligibilityItem(
                                          text: entry.value,
                                        ),
                                      ),
                                    )
                                    .toList(growable: false),
                              ),
                      ),
                      const SizedBox(height: 16),
                      _ScholarshipSectionCard(
                        icon: Icons.fact_check_outlined,
                        iconColor: _P.accent,
                        title: AppLocalizations.of(
                          context,
                        )!.uiScholarshipProfile,
                        subtitle: AppLocalizations.of(
                          context,
                        )!.uiACleanerBreakdownOfTheProviderDestinationAndTrack,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            ...profileRows.asMap().entries.map(
                              (entry) => Padding(
                                padding: EdgeInsets.only(
                                  bottom: entry.key == profileRows.length - 1
                                      ? 0
                                      : 8,
                                ),
                                child: _ProfileRow(data: entry.value),
                              ),
                            ),
                            if (scholarship.tags.isNotEmpty) ...[
                              const SizedBox(height: 16),
                              Text(
                                'Highlights',
                                style: AppTypography.product(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  color: _P.textPrimary,
                                ),
                              ),
                              const SizedBox(height: 10),
                              Wrap(
                                spacing: 8,
                                runSpacing: 8,
                                children: scholarship.tags
                                    .take(6)
                                    .map((tag) => _TagChip(label: tag))
                                    .toList(growable: false),
                              ),
                            ],
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      _ScholarshipSectionCard(
                        icon: Icons.launch_rounded,
                        iconColor: _P.primaryDark,
                        title: AppLocalizations.of(context)!.uiApplicationLink,
                        subtitle: AppLocalizations.of(
                          context,
                        )!.uiContinueWithConfidenceOnTheOfficialDestination,
                        child: _ApplicationPreviewCard(
                          link: scholarship.link,
                          hostLabel: _linkHost,
                          enabled: hasLink,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _ScholarshipHeroCard extends StatelessWidget {
  final ScholarshipModel scholarship;
  final String badgeLabel;
  final String? secondaryBadgeLabel;
  final String provider;
  final String title;
  final String? location;
  final String? deadline;
  final List<String> chips;

  const _ScholarshipHeroCard({
    required this.scholarship,
    required this.badgeLabel,
    required this.secondaryBadgeLabel,
    required this.provider,
    required this.title,
    required this.location,
    required this.deadline,
    required this.chips,
  });

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final isCompact = width < 380;
    final imageUrl = scholarship.imageUrl?.trim();
    final hasImage = imageUrl != null && imageUrl.isNotEmpty;

    return Container(
      height: isCompact ? 244 : 262,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(32),
        boxShadow: [
          BoxShadow(
            color: _P.primary.withValues(alpha: 0.18),
            blurRadius: 26,
            offset: const Offset(0, 14),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(32),
        child: Stack(
          fit: StackFit.expand,
          children: [
            if (hasImage)
              Image.network(
                imageUrl,
                fit: BoxFit.cover,
                loadingBuilder: (context, child, loadingProgress) {
                  if (loadingProgress == null) {
                    return child;
                  }
                  return const _HeroGradientFallback();
                },
                errorBuilder: (context, error, stackTrace) {
                  return const _HeroGradientFallback();
                },
              )
            else
              const _HeroGradientFallback(),
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    _P.primaryDark.withValues(alpha: hasImage ? 0.42 : 0.08),
                    Colors.black.withValues(alpha: 0.64),
                  ],
                ),
              ),
            ),
            Positioned(
              top: -18,
              right: -18,
              child: Container(
                width: 148,
                height: 148,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.08),
                  shape: BoxShape.circle,
                ),
              ),
            ),
            Positioned(
              left: -24,
              bottom: -42,
              child: Container(
                width: 134,
                height: 134,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.06),
                  shape: BoxShape.circle,
                ),
              ),
            ),
            Padding(
              padding: EdgeInsets.fromLTRB(
                isCompact ? 16 : 20,
                isCompact ? 16 : 20,
                isCompact ? 16 : 20,
                isCompact ? 16 : 20,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            _GlassPill(label: badgeLabel),
                            if (secondaryBadgeLabel != null)
                              _GlassPill(
                                label: secondaryBadgeLabel!,
                                backgroundColor: _P.secondary.withValues(
                                  alpha: 0.24,
                                ),
                              ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      Container(
                        width: isCompact ? 46 : 50,
                        height: isCompact ? 46 : 50,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.12),
                          ),
                        ),
                        child: const Icon(
                          Icons.school_rounded,
                          size: 24,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                  const Spacer(),
                  Text(
                    provider.toUpperCase(),
                    style: AppTypography.product(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0,
                      color: Colors.white.withValues(alpha: 0.76),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: AppTypography.product(
                      fontSize: isCompact ? 21 : 24,
                      fontWeight: FontWeight.w800,
                      height: 1.12,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 14,
                    runSpacing: 8,
                    children: [
                      if (location != null)
                        _HeroMetaLine(
                          icon: Icons.location_on_outlined,
                          text: location!,
                        ),
                      if (deadline != null)
                        _HeroMetaLine(
                          icon: Icons.event_outlined,
                          text: deadline!,
                        ),
                    ],
                  ),
                  if (chips.isNotEmpty) ...[
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: chips
                          .map(
                            (chip) => _GlassPill(
                              label: chip,
                              compact: true,
                              backgroundColor: Colors.white.withValues(
                                alpha: 0.10,
                              ),
                            ),
                          )
                          .toList(growable: false),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _HeroGradientFallback extends StatelessWidget {
  const _HeroGradientFallback();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [_P.primary, _P.primaryDark],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Stack(
        children: [
          Positioned(
            top: -24,
            right: -18,
            child: Container(
              width: 148,
              height: 148,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.10),
                shape: BoxShape.circle,
              ),
            ),
          ),
          Positioned(
            left: -18,
            bottom: -34,
            child: Container(
              width: 124,
              height: 124,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.08),
                shape: BoxShape.circle,
              ),
            ),
          ),
          Center(
            child: Icon(
              Icons.school_rounded,
              size: 72,
              color: Colors.white.withValues(alpha: 0.20),
            ),
          ),
        ],
      ),
    );
  }
}

class _PageSectionHeading extends StatelessWidget {
  final String eyebrow;
  final String title;
  final String subtitle;

  const _PageSectionHeading({
    required this.eyebrow,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          eyebrow,
          style: AppTypography.product(
            fontSize: 10,
            fontWeight: FontWeight.w700,
            letterSpacing: 0,
            color: _P.secondary,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          title,
          style: AppTypography.product(
            fontSize: 22,
            fontWeight: FontWeight.w800,
            color: _P.textPrimary,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          subtitle,
          style: AppTypography.product(
            fontSize: 12.25,
            height: 1.55,
            color: _P.textSecondary,
          ),
        ),
      ],
    );
  }
}

class _ScholarshipStatsWrap extends StatelessWidget {
  final List<_ScholarshipStatData> stats;

  const _ScholarshipStatsWrap({required this.stats});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final maxWidth = constraints.maxWidth;
        final itemWidth = (maxWidth - 12) / 2;

        return Wrap(
          spacing: 12,
          runSpacing: 12,
          children: stats
              .map(
                (data) => SizedBox(
                  width: itemWidth,
                  child: _ScholarshipStatCard(data: data),
                ),
              )
              .toList(growable: false),
        );
      },
    );
  }
}

class _ScholarshipStatCard extends StatelessWidget {
  final _ScholarshipStatData data;

  const _ScholarshipStatCard({required this.data});

  @override
  Widget build(BuildContext context) {
    final borderColor = data.highlight
        ? data.accentColor.withValues(alpha: 0.18)
        : _P.border;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: data.highlight
            ? data.accentColor.withValues(alpha: 0.06)
            : _P.surface,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: borderColor),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: data.accentColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(data.icon, size: 20, color: data.accentColor),
          ),
          const SizedBox(height: 14),
          Text(
            data.label,
            style: AppTypography.product(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: _P.textSecondary,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            data.value,
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
            style: AppTypography.product(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              height: 1.35,
              color: _P.textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}

class _ScholarshipSectionCard extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;
  final Widget child;

  const _ScholarshipSectionCard({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: _P.surface,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: _P.border.withValues(alpha: 0.92)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: iconColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(icon, size: 22, color: iconColor),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: AppTypography.product(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: _P.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: AppTypography.product(
                        fontSize: 11.75,
                        height: 1.5,
                        color: _P.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          child,
        ],
      ),
    );
  }
}

class _EligibilityItem extends StatelessWidget {
  final String text;

  const _EligibilityItem({required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: _P.background,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: _P.border.withValues(alpha: 0.86)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 26,
            height: 26,
            decoration: BoxDecoration(
              color: _P.secondary.withValues(alpha: 0.14),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.check_rounded, size: 16, color: _P.secondary),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: AppTypography.product(
                fontSize: 12.5,
                height: 1.55,
                color: _P.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ProfileRow extends StatelessWidget {
  final _ScholarshipProfileRowData data;

  const _ProfileRow({required this.data});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: _P.background,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: _P.border.withValues(alpha: 0.84)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(data.icon, size: 18, color: _P.primary),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  data.label,
                  style: AppTypography.product(
                    fontSize: 10.5,
                    fontWeight: FontWeight.w600,
                    color: _P.textSecondary,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  data.value,
                  style: AppTypography.product(
                    fontSize: 12.75,
                    fontWeight: FontWeight.w600,
                    height: 1.45,
                    color: _P.textPrimary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ApplicationPreviewCard extends StatelessWidget {
  final String link;
  final String? hostLabel;
  final bool enabled;

  const _ApplicationPreviewCard({
    required this.link,
    required this.hostLabel,
    required this.enabled,
  });

  @override
  Widget build(BuildContext context) {
    final previewText = enabled
        ? link.trim()
        : 'The provider has not attached an external application link yet.';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            _P.primary.withValues(alpha: enabled ? 0.07 : 0.03),
            _P.primaryDark.withValues(alpha: enabled ? 0.05 : 0.02),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: enabled
              ? _P.primary.withValues(alpha: 0.14)
              : _P.border.withValues(alpha: 0.92),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: enabled
                  ? _P.primary.withValues(alpha: 0.14)
                  : _P.textSecondary.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(
              enabled ? Icons.language_rounded : Icons.hourglass_top_rounded,
              color: enabled ? _P.primary : _P.textSecondary,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  hostLabel ?? 'Official scholarship source',
                  style: AppTypography.product(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w700,
                    color: _P.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  previewText,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.product(
                    fontSize: 11.75,
                    height: 1.55,
                    color: _P.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ScholarshipActionBar extends StatelessWidget {
  final String? hostLabel;
  final bool enabled;
  final VoidCallback? onTap;

  const _ScholarshipActionBar({
    required this.hostLabel,
    required this.enabled,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _P.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: _P.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _PrimaryActionButton(
            label: enabled
                ? 'Apply on ${hostLabel ?? 'official page'}'
                : 'Application link unavailable',
            icon: enabled ? Icons.open_in_new_rounded : Icons.link_off_rounded,
            onTap: onTap,
          ),
        ],
      ),
    );
  }
}

class _PrimaryActionButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback? onTap;

  const _PrimaryActionButton({
    required this.label,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isEnabled = onTap != null;

    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(18),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Ink(
          height: 54,
          decoration: BoxDecoration(
            color: isEnabled ? null : _P.border,
            gradient: isEnabled
                ? LinearGradient(
                    colors: [_P.primary, _P.primaryDark],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  )
                : null,
            borderRadius: BorderRadius.circular(18),
          ),
          child: AppInlineIconLabel(
            icon: icon,
            iconSize: 18,
            iconColor: Colors.white,
            gap: 10,
            label: Flexible(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTypography.product(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _TopBarIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onTap;
  final Color? iconColor;
  final Color? fillColor;

  const _TopBarIconButton({
    required this.icon,
    required this.onTap,
    this.iconColor,
    this.fillColor,
  });

  @override
  Widget build(BuildContext context) {
    final enabled = onTap != null;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Ink(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            color: fillColor ?? _P.surface,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: _P.border),
          ),
          child: AppDirectionalIcon(
            icon,
            size: 18,
            color: enabled
                ? iconColor ?? _P.textPrimary
                : _P.textSecondary.withValues(alpha: 0.55),
          ),
        ),
      ),
    );
  }
}

class _GlassPill extends StatelessWidget {
  final String label;
  final Color? backgroundColor;
  final bool compact;

  const _GlassPill({
    required this.label,
    this.backgroundColor,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 10 : 12,
        vertical: compact ? 5 : 6,
      ),
      decoration: BoxDecoration(
        color: backgroundColor ?? Colors.white.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Colors.white.withValues(alpha: 0.14)),
      ),
      child: Text(
        label,
        style: AppTypography.product(
          fontSize: compact ? 10 : 10.5,
          fontWeight: FontWeight.w700,
          letterSpacing: 0,
          color: Colors.white,
        ),
      ),
    );
  }
}

class _HeroMetaLine extends StatelessWidget {
  final IconData icon;
  final String text;

  const _HeroMetaLine({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 260),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 15, color: Colors.white.withValues(alpha: 0.82)),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              text,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTypography.product(
                fontSize: 11.5,
                fontWeight: FontWeight.w500,
                color: Colors.white.withValues(alpha: 0.82),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TagChip extends StatelessWidget {
  final String label;

  const _TagChip({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: _P.primary.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: _P.primary.withValues(alpha: 0.10)),
      ),
      child: Text(
        label,
        style: AppTypography.product(
          fontSize: 10.5,
          fontWeight: FontWeight.w600,
          color: _P.primary,
        ),
      ),
    );
  }
}

class _SoftOrb extends StatelessWidget {
  final double size;
  final Color color;

  const _SoftOrb({required this.size, required this.color});

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(color: color, shape: BoxShape.circle),
      ),
    );
  }
}

class _ScholarshipStatData {
  final IconData icon;
  final String label;
  final String value;
  final Color accentColor;
  final bool highlight;

  const _ScholarshipStatData({
    required this.icon,
    required this.label,
    required this.value,
    required this.accentColor,
    this.highlight = false,
  });
}

class _ScholarshipProfileRowData {
  final IconData icon;
  final String label;
  final String value;

  const _ScholarshipProfileRowData({
    required this.icon,
    required this.label,
    required this.value,
  });
}
