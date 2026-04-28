import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../l10n/generated/app_localizations.dart';
import '../../models/user_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/company_provider.dart';
import '../../services/document_access_service.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_typography.dart';
import '../../utils/company_dashboard_palette.dart';
import '../../utils/document_upload_validator.dart';
import '../../widgets/app_shell_background.dart';
import '../../widgets/profile_avatar.dart';
import '../../widgets/shared/app_feedback.dart';
import '../../widgets/shared/app_loading.dart';
import '../settings/about_futuregate_screen.dart';
import '../settings/help_center_screen.dart';
import '../settings/logout_confirmation_sheet.dart';
import '../settings/security_privacy_screen.dart';
import '../settings/settings_flow_theme.dart';
import '../settings/settings_flow_widgets.dart';

class CompanyProfileScreen extends StatelessWidget {
  const CompanyProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    AppColors.of(context);
    final authProvider = context.watch<AuthProvider>();
    final user = authProvider.userModel;
    if (user == null) {
      return const AppShellBackground(
        child: Scaffold(
          backgroundColor: Colors.transparent,
          body: SafeArea(child: AppLoadingView(showBottomBar: true)),
        ),
      );
    }

    final companyName = _companyName(user);
    final description = _companyDescription(user);
    final websiteUri = _websiteUri(user.website ?? '');
    final providerLabel = authProvider.linkedProviderLabel;
    final missingItems = _missingProfileItems(user);

    return AppShellBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: _CompanySettingsAppBar(
          title: AppLocalizations.of(context)!.companyProfileTitle,
        ),
        body: Stack(
          children: [
            const Positioned(
              top: -120,
              right: -80,
              child: _BackdropOrb(220, Color(0x1414B8A6)),
            ),
            const Positioned(
              top: 190,
              left: -70,
              child: _BackdropOrb(160, Color(0x124328D8)),
            ),
            SafeArea(
              top: false,
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 28),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildHeroCard(
                      context,
                      user: user,
                      companyName: companyName,
                      websiteUri: websiteUri,
                    ),
                    if (missingItems.isNotEmpty) ...[
                      const SizedBox(height: 18),
                      _buildIncompleteProfileCard(context, missingItems),
                    ],
                    const SizedBox(height: 18),
                    const SettingsSectionHeading(
                      title: 'Brand Story',
                      subtitle:
                          'A sharper company story makes the profile feel more confident and trustworthy.',
                    ),
                    const SizedBox(height: 10),
                    SettingsPanel(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            description,
                            style: AppTypography.product(
                              fontSize: 14,
                              height: 1.7,
                              fontWeight: FontWeight.w500,
                              color: CompanyDashboardPalette.textPrimary,
                            ),
                          ),
                          if ((user.description ?? '').trim().isEmpty) ...[
                            const SizedBox(height: 14),
                            SettingsInfoBanner(
                              icon: Icons.edit_note_rounded,
                              title: 'Story still missing',
                              message:
                                  'Add a few lines about what your company builds and what students can expect from your team.',
                              color: CompanyDashboardPalette.accent,
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(height: 18),
                    const SettingsSectionHeading(
                      title: 'Details',
                      subtitle:
                          'The essentials students and applicants usually look for first.',
                    ),
                    const SizedBox(height: 10),
                    _buildDetailsGrid(context, user, websiteUri, providerLabel),
                    const SizedBox(height: 18),
                    const SettingsSectionHeading(
                      title: 'Verification',
                      subtitle:
                          'Keep your company presence trusted with an up-to-date commercial register.',
                    ),
                    const SizedBox(height: 10),
                    _buildCommercialRegisterCard(context, user),
                    const SizedBox(height: 18),
                    _buildQuickLinks(context),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _companyName(UserModel user) {
    final companyName = (user.companyName ?? '').trim();
    if (companyName.isNotEmpty) {
      return companyName;
    }
    return user.fullName.trim().isNotEmpty ? user.fullName.trim() : 'Company';
  }

  String _companyDescription(UserModel user) {
    final description = (user.description ?? '').trim();
    if (description.isNotEmpty) {
      return description;
    }
    return 'Build a strong first impression with a short company story, clear contact details, and a polished visual identity.';
  }

  Uri? _websiteUri(String rawValue) {
    final trimmed = rawValue.trim();
    if (trimmed.isEmpty) {
      return null;
    }
    final normalized = trimmed.contains('://') ? trimmed : 'https://$trimmed';
    return Uri.tryParse(normalized);
  }

  int _profileCompletion(UserModel user) {
    const totalChecks = 8;
    final completedChecks = totalChecks - _missingProfileItems(user).length;
    return ((completedChecks / totalChecks) * 100).round();
  }

  List<_CompanyMissingItem> _missingProfileItems(UserModel user) {
    final items = <_CompanyMissingItem>[];
    if ((user.companyName ?? '').trim().isEmpty) {
      items.add(
        _CompanyMissingItem(
          label: 'Company name',
          icon: Icons.business_rounded,
          color: CompanyDashboardPalette.primary,
        ),
      );
    }
    if ((user.sector ?? '').trim().isEmpty) {
      items.add(
        _CompanyMissingItem(
          label: 'Sector',
          icon: Icons.factory_outlined,
          color: CompanyDashboardPalette.primaryDark,
        ),
      );
    }
    if ((user.description ?? '').trim().isEmpty) {
      items.add(
        _CompanyMissingItem(
          label: 'Brand story',
          icon: Icons.notes_rounded,
          color: CompanyDashboardPalette.accent,
        ),
      );
    }
    if (user.phone.trim().isEmpty) {
      items.add(
        _CompanyMissingItem(
          label: 'Phone',
          icon: Icons.phone_outlined,
          color: CompanyDashboardPalette.secondary,
        ),
      );
    }
    if (user.location.trim().isEmpty) {
      items.add(
        _CompanyMissingItem(
          label: 'Location',
          icon: Icons.location_on_outlined,
          color: CompanyDashboardPalette.info,
        ),
      );
    }
    if ((user.website ?? '').trim().isEmpty) {
      items.add(
        _CompanyMissingItem(
          label: 'Website',
          icon: Icons.language_rounded,
          color: CompanyDashboardPalette.accent,
        ),
      );
    }
    if ((user.logo ?? '').trim().isEmpty) {
      items.add(
        _CompanyMissingItem(
          label: 'Logo',
          icon: Icons.image_outlined,
          color: CompanyDashboardPalette.secondaryDark,
        ),
      );
    }
    if (!user.hasCommercialRegister) {
      items.add(
        _CompanyMissingItem(
          label: 'Commercial register',
          icon: Icons.verified_user_outlined,
          color: CompanyDashboardPalette.warning,
        ),
      );
    }
    return items;
  }

  int _contactCount(UserModel user) {
    return [
      user.email.trim().isNotEmpty,
      user.phone.trim().isNotEmpty,
      user.location.trim().isNotEmpty,
      (user.website ?? '').trim().isNotEmpty,
    ].where((v) => v).length;
  }

  Widget _buildHeroCard(
    BuildContext context, {
    required UserModel user,
    required String companyName,
    required Uri? websiteUri,
  }) {
    final approvalStatus = user.normalizedApprovalStatus;
    final isApproved = approvalStatus == 'approved';
    final approvalLabel = switch (approvalStatus) {
      'pending' => 'Pending review',
      'rejected' => 'Rejected',
      _ => '',
    };
    final approvalIcon = switch (approvalStatus) {
      'pending' => Icons.pending_actions_rounded,
      'rejected' => Icons.gpp_bad_outlined,
      _ => Icons.verified_rounded,
    };
    final approvalForegroundColor = switch (approvalStatus) {
      'pending' => CompanyDashboardPalette.accent,
      'rejected' => CompanyDashboardPalette.error,
      _ => CompanyDashboardPalette.success,
    };
    final approvalBackgroundColor = approvalForegroundColor.withValues(
      alpha: AppColors.isDark ? 0.18 : 0.12,
    );

    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxWidth < 390;

        return Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                CompanyDashboardPalette.primaryDark,
                CompanyDashboardPalette.primary,
                CompanyDashboardPalette.secondary,
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: SettingsFlowTheme.radius(24),
            boxShadow: [
              BoxShadow(
                color: CompanyDashboardPalette.primary.withValues(
                  alpha: AppColors.isDark ? 0.32 : 0.18,
                ),
                blurRadius: 24,
                offset: const Offset(0, 14),
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
                    padding: const EdgeInsets.all(3),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.14),
                      shape: BoxShape.circle,
                    ),
                    child: ProfileAvatar(user: user, radius: compact ? 28 : 32),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Flexible(
                              child: Text(
                                companyName,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: AppTypography.product(
                                  fontSize: compact ? 19 : 21,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white,
                                  height: 1.08,
                                ),
                              ),
                            ),
                            if (isApproved) ...[
                              const SizedBox(width: 7),
                              const _VerifiedNameBadge(),
                            ],
                          ],
                        ),
                        if ((user.sector ?? '').trim().isNotEmpty) ...[
                          const SizedBox(height: 5),
                          Text(
                            (user.sector ?? '').trim(),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AppTypography.product(
                              fontSize: 12.5,
                              fontWeight: FontWeight.w600,
                              color: Colors.white.withValues(alpha: 0.82),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  if (!compact && !isApproved) ...[
                    const SizedBox(width: 10),
                    _StatusBadge(
                      label: approvalLabel,
                      icon: approvalIcon,
                      backgroundColor: approvalBackgroundColor,
                      foregroundColor: approvalForegroundColor,
                    ),
                  ],
                ],
              ),
              if (compact && !isApproved) ...[
                const SizedBox(height: 12),
                _StatusBadge(
                  label: approvalLabel,
                  icon: approvalIcon,
                  backgroundColor: approvalBackgroundColor,
                  foregroundColor: approvalForegroundColor,
                ),
              ],
              const SizedBox(height: 14),
              SettingsButtonGroup(
                spacing: 8,
                breakpoint: 380,
                children: [
                  _HeroActionButton(
                    label: 'Edit profile',
                    icon: Icons.edit_outlined,
                    filled: true,
                    onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const EditCompanyProfileScreen(),
                      ),
                    ),
                  ),
                  if (websiteUri != null)
                    _HeroActionButton(
                      label: 'Website',
                      icon: Icons.open_in_new_rounded,
                      onPressed: () => _launchUri(
                        context,
                        websiteUri,
                        failureMessage: 'Could not open the website.',
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: _heroMetric(
                      '${_profileCompletion(user)}%',
                      'Complete',
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _heroMetric('${_contactCount(user)}/4', 'Contact'),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildIncompleteProfileCard(
    BuildContext context,
    List<_CompanyMissingItem> missingItems,
  ) {
    final missingCount = missingItems.length;
    final message = missingCount == 1
        ? '1 detail is still missing from the company profile.'
        : '$missingCount details are still missing from the company profile.';

    return SettingsPanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SettingsIconBox(
                icon: Icons.fact_check_outlined,
                color: CompanyDashboardPalette.accent,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Profile incomplete',
                      style: SettingsFlowTheme.sectionTitle(),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '$message Add what is missing so students see a clearer, more trusted company page.',
                      style: SettingsFlowTheme.caption(),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final item in missingItems) _CompanyMissingChip(item: item),
            ],
          ),
          const SizedBox(height: 16),
          SettingsPrimaryButton(
            label: 'Complete profile',
            icon: Icons.edit_outlined,
            backgroundColor: CompanyDashboardPalette.accent,
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => const EditCompanyProfileScreen(),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _heroMetric(String value, String label) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.12),
        borderRadius: SettingsFlowTheme.radius(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTypography.product(
              fontSize: 15.5,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTypography.product(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: Colors.white.withValues(alpha: 0.8),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailsGrid(
    BuildContext context,
    UserModel user,
    Uri? websiteUri,
    String providerLabel,
  ) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxWidth < 540;
        final width = compact
            ? constraints.maxWidth
            : (constraints.maxWidth - 12) / 2;
        return Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            SizedBox(
              width: width,
              child: _DetailTile(
                icon: Icons.mail_outline_rounded,
                label: 'Email',
                value: user.email,
                accentColor: CompanyDashboardPalette.primary,
                onTap: user.email.trim().isEmpty
                    ? null
                    : () => _launchUri(
                        context,
                        Uri(scheme: 'mailto', path: user.email.trim()),
                        failureMessage: 'Could not open email right now.',
                      ),
              ),
            ),
            SizedBox(
              width: width,
              child: _DetailTile(
                icon: Icons.phone_outlined,
                label: 'Phone',
                value: user.phone.trim().isNotEmpty
                    ? user.phone.trim()
                    : 'Add a company phone number',
                accentColor: CompanyDashboardPalette.secondary,
              ),
            ),
            SizedBox(
              width: width,
              child: _DetailTile(
                icon: Icons.location_on_outlined,
                label: 'Location',
                value: user.location.trim().isNotEmpty
                    ? user.location.trim()
                    : 'Add your company location',
                accentColor: CompanyDashboardPalette.info,
              ),
            ),
            SizedBox(
              width: width,
              child: _DetailTile(
                icon: Icons.language_rounded,
                label: 'Website',
                value: (user.website ?? '').trim().isNotEmpty
                    ? (user.website ?? '').trim()
                    : 'Add your website',
                accentColor: CompanyDashboardPalette.accent,
                onTap: websiteUri == null
                    ? null
                    : () => _launchUri(
                        context,
                        websiteUri,
                        failureMessage: 'Could not open the website.',
                      ),
              ),
            ),
            SizedBox(
              width: width,
              child: _DetailTile(
                icon: Icons.factory_outlined,
                label: 'Sector',
                value: (user.sector ?? '').trim().isNotEmpty
                    ? (user.sector ?? '').trim()
                    : 'Add a sector or specialty',
                accentColor: CompanyDashboardPalette.primaryDark,
              ),
            ),
            SizedBox(
              width: width,
              child: _DetailTile(
                icon: Icons.verified_user_outlined,
                label: 'Account',
                value: providerLabel,
                accentColor: CompanyDashboardPalette.success,
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildCommercialRegisterCard(BuildContext context, UserModel user) {
    final uploadedAt = user.commercialRegisterUploadedAt;
    final uploadedAtLabel = uploadedAt == null
        ? 'Not available'
        : DateFormat('MMM d, yyyy').format(uploadedAt.toDate());
    final registerSummary = switch (user.normalizedApprovalStatus) {
      'pending' =>
        'The required document is attached and waiting for admin review.',
      'rejected' =>
        'The required document is attached, but the company approval still needs attention.',
      _ => 'The required document is attached and the company is approved.',
    };
    final approvalTitle = switch (user.normalizedApprovalStatus) {
      'pending' => 'Approval pending',
      'rejected' => 'Approval needs changes',
      _ => 'Company approved',
    };
    final approvalMessage = switch (user.normalizedApprovalStatus) {
      'pending' =>
        'Your commercial register is uploaded and the admin team still needs to review this company account.',
      'rejected' =>
        'Your document is uploaded, but the company account still needs corrections before it can be approved.',
      _ =>
        'Your commercial register is uploaded and the company account is approved.',
    };
    final approvalColor = switch (user.normalizedApprovalStatus) {
      'pending' => CompanyDashboardPalette.accent,
      'rejected' => CompanyDashboardPalette.error,
      _ => CompanyDashboardPalette.success,
    };
    final approvalIcon = switch (user.normalizedApprovalStatus) {
      'pending' => Icons.pending_actions_rounded,
      'rejected' => Icons.gpp_bad_outlined,
      _ => Icons.verified_rounded,
    };
    return SettingsPanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SettingsIconBox(
                icon: user.hasCommercialRegister
                    ? Icons.verified_user_outlined
                    : Icons.file_upload_outlined,
                color: user.hasCommercialRegister
                    ? CompanyDashboardPalette.success
                    : CompanyDashboardPalette.accent,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Commercial Register',
                      style: SettingsFlowTheme.sectionTitle(),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      user.hasCommercialRegister
                          ? registerSummary
                          : 'Upload a current document to keep the company profile complete and trusted.',
                      style: SettingsFlowTheme.caption(),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (user.hasCommercialRegister && !user.isCompanyApproved) ...[
            const SizedBox(height: 16),
            SettingsInfoBanner(
              icon: approvalIcon,
              title: approvalTitle,
              message: approvalMessage,
              color: approvalColor,
            ),
          ],
          const SizedBox(height: 16),
          if (user.hasCommercialRegister) ...[
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: SettingsFlowPalette.background,
                borderRadius: SettingsFlowTheme.radius(20),
                border: Border.all(color: SettingsFlowPalette.border),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    user.commercialRegisterFileName.trim().isNotEmpty
                        ? user.commercialRegisterFileName.trim()
                        : 'Document uploaded',
                    style: SettingsFlowTheme.cardTitle(),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Uploaded: $uploadedAtLabel',
                    style: SettingsFlowTheme.caption(),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            SettingsButtonGroup(
              children: [
                SettingsSecondaryButton(
                  label: 'View',
                  icon: Icons.visibility_outlined,
                  color: CompanyDashboardPalette.primary,
                  onPressed: () =>
                      _openCommercialRegister(context, companyId: user.uid),
                ),
                SettingsPrimaryButton(
                  label: 'Download',
                  icon: Icons.download_outlined,
                  backgroundColor: CompanyDashboardPalette.accent,
                  onPressed: () => _openCommercialRegister(
                    context,
                    companyId: user.uid,
                    download: true,
                  ),
                ),
              ],
            ),
          ] else ...[
            SettingsInfoBanner(
              icon: Icons.info_outline_rounded,
              title: 'Document missing',
              message:
                  'A current commercial register reinforces trust and helps keep the company profile ready for review.',
              color: CompanyDashboardPalette.accent,
            ),
            const SizedBox(height: 14),
            SettingsPrimaryButton(
              label: 'Update profile',
              icon: Icons.edit_outlined,
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const EditCompanyProfileScreen(),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildQuickLinks(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return SettingsPanel(
      child: Column(
        children: [
          SettingsListRow(
            icon: Icons.edit_outlined,
            iconColor: CompanyDashboardPalette.primary,
            title: l10n.editCompanyProfileTitle,
            subtitle: l10n.editCompanyProfileSubtitle,
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => const EditCompanyProfileScreen(),
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
              MaterialPageRoute(builder: (_) => const SecurityPrivacyScreen()),
            ),
          ),
          const SizedBox(height: 10),
          SettingsListRow(
            icon: Icons.help_outline_rounded,
            iconColor: CompanyDashboardPalette.accent,
            title: l10n.helpCenterTitle,
            subtitle: l10n.helpCenterSubtitle,
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const HelpCenterScreen()),
            ),
          ),
          const SizedBox(height: 10),
          SettingsListRow(
            icon: Icons.info_outline_rounded,
            iconColor: CompanyDashboardPalette.info,
            title: l10n.aboutFutureGateTitle,
            subtitle: l10n.aboutFutureGateSubtitle,
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const AboutFutureGateScreen()),
            ),
          ),
          const SizedBox(height: 10),
          SettingsListRow(
            icon: Icons.logout_rounded,
            iconColor: SettingsFlowPalette.error,
            title: l10n.signOutTitle,
            subtitle: l10n.signOutSubtitle,
            destructive: true,
            compact: true,
            onTap: () => showLogoutConfirmationSheet(context),
          ),
        ],
      ),
    );
  }

  Future<void> _launchUri(
    BuildContext context,
    Uri uri, {
    required String failureMessage,
  }) async {
    final launched = await launchUrl(
      uri,
      mode: LaunchMode.platformDefault,
      webOnlyWindowName: '_blank',
    );
    if (!launched && context.mounted) {
      context.showAppSnackBar(
        failureMessage,
        title: 'Open unavailable',
        type: AppFeedbackType.error,
      );
    }
  }

  Future<void> _openCommercialRegister(
    BuildContext context, {
    required String companyId,
    bool download = false,
  }) async {
    try {
      final document = await DocumentAccessService()
          .getCompanyCommercialRegister(companyId: companyId);
      final uri = Uri.tryParse(
        download ? document.downloadUrl : document.viewUrl,
      );
      if (uri == null) {
        throw Exception('File unavailable.');
      }
      final launched = await launchUrl(
        uri,
        mode: LaunchMode.platformDefault,
        webOnlyWindowName: '_blank',
      );
      if (!launched && context.mounted) {
        context.showAppSnackBar(
          'We couldn\'t open the document right now.',
          title: 'Document unavailable',
          type: AppFeedbackType.error,
        );
      }
    } catch (error) {
      if (!context.mounted) {
        return;
      }
      context.showAppSnackBar(
        _documentErrorMessage(error),
        title: 'Document unavailable',
        type: AppFeedbackType.error,
      );
    }
  }

  String _documentErrorMessage(Object error) {
    final message = error.toString().toLowerCase();
    if (message.contains('permission') || message.contains('403')) {
      return 'Permission denied while opening the document.';
    }
    if (message.contains('404') || message.contains('not found')) {
      return 'The requested document is no longer available.';
    }
    return 'We couldn\'t open the document right now.';
  }
}

class EditCompanyProfileScreen extends StatefulWidget {
  const EditCompanyProfileScreen({super.key});

  @override
  State<EditCompanyProfileScreen> createState() =>
      _EditCompanyProfileScreenState();
}

class _EditCompanyProfileScreenState extends State<EditCompanyProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _companyNameController = TextEditingController();
  final _sectorController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _phoneController = TextEditingController();
  final _locationController = TextEditingController();
  final _websiteController = TextEditingController();

  PlatformFile? _commercialRegisterFile;
  String? _commercialRegisterError;
  bool _saving = false;
  bool _uploadingLogo = false;

  @override
  void initState() {
    super.initState();
    final user = context.read<AuthProvider>().userModel;
    if (user != null) {
      _companyNameController.text = user.companyName ?? '';
      _sectorController.text = user.sector ?? '';
      _descriptionController.text = user.description ?? '';
      _phoneController.text = user.phone;
      _locationController.text = user.location;
      _websiteController.text = user.website ?? '';
    }
  }

  @override
  void dispose() {
    _companyNameController.dispose();
    _sectorController.dispose();
    _descriptionController.dispose();
    _phoneController.dispose();
    _locationController.dispose();
    _websiteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().userModel;
    if (user == null) {
      return const AppShellBackground(
        child: Scaffold(
          backgroundColor: Colors.transparent,
          body: SafeArea(child: AppLoadingView(showBottomBar: true)),
        ),
      );
    }

    return AppShellBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: _CompanySettingsAppBar(
          title: AppLocalizations.of(context)!.editCompanyProfileTitle,
        ),
        bottomNavigationBar: SafeArea(
          top: false,
          child: Container(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
            decoration: BoxDecoration(
              color: SettingsFlowPalette.surface,
              border: Border(
                top: BorderSide(color: SettingsFlowPalette.border),
              ),
            ),
            child: ElevatedButton.icon(
              onPressed: _saving ? null : _save,
              icon: _saving
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.check_rounded),
              label: Text(
                _saving ? 'Saving changes...' : 'Save Changes',
                style: AppTypography.product(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
              style: ElevatedButton.styleFrom(
                minimumSize: const Size.fromHeight(54),
                elevation: 0,
                backgroundColor: CompanyDashboardPalette.primary,
                foregroundColor: Colors.white,
                disabledBackgroundColor: CompanyDashboardPalette.primary
                    .withValues(alpha: 0.45),
                shape: RoundedRectangleBorder(
                  borderRadius: SettingsFlowTheme.radius(20),
                ),
              ),
            ),
          ),
        ),
        body: Stack(
          children: [
            const Positioned(
              top: -110,
              right: -72,
              child: _BackdropOrb(210, Color(0x1214B8A6)),
            ),
            SafeArea(
              top: false,
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 110),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildEditorIntro(user),
                      const SizedBox(height: 18),
                      _buildIdentitySection(),
                      const SizedBox(height: 18),
                      _buildContactSection(),
                      const SizedBox(height: 18),
                      _buildLogoSection(user),
                      const SizedBox(height: 18),
                      _buildRegisterSection(user),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEditorIntro(UserModel user) {
    return SettingsPanel(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Polish your public company presence',
            style: SettingsFlowTheme.heroTitle(),
          ),
          const SizedBox(height: 8),
          Text(
            'Keep the profile crisp, trustworthy, and ready for students to explore.',
            style: SettingsFlowTheme.caption(),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              ProfileAvatar(user: user, radius: 30),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      (user.companyName ?? user.fullName).trim(),
                      style: SettingsFlowTheme.cardTitle(),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      user.hasCommercialRegister
                          ? 'Verification document is already attached.'
                          : 'Commercial register still needs attention.',
                      style: SettingsFlowTheme.caption(),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildIdentitySection() {
    return _panel(
      title: 'Basic Identity',
      subtitle: 'Shape the first impression students get from your company.',
      icon: Icons.apartment_rounded,
      child: Column(
        children: [
          _field(
            label: 'Company Name',
            hint: 'Your public company name',
            icon: Icons.business_rounded,
            controller: _companyNameController,
            validator: (value) {
              if ((value ?? '').trim().isEmpty) {
                return 'Company name is required.';
              }
              return null;
            },
          ),
          const SizedBox(height: 14),
          _field(
            label: 'Sector',
            hint: 'Technology, finance, design, education...',
            icon: Icons.factory_outlined,
            controller: _sectorController,
          ),
          const SizedBox(height: 14),
          _field(
            label: 'Description',
            hint:
                'What does your company build, who do you serve, and what can students expect?',
            icon: Icons.notes_rounded,
            controller: _descriptionController,
            maxLines: 5,
          ),
        ],
      ),
    );
  }

  Widget _buildContactSection() {
    return _panel(
      title: 'Contact & Presence',
      subtitle:
          'Make it easy for students to understand where your company is and how to reach it.',
      icon: Icons.public_rounded,
      child: Column(
        children: [
          _field(
            label: 'Phone',
            hint: 'Company phone number',
            icon: Icons.phone_outlined,
            controller: _phoneController,
            keyboardType: TextInputType.phone,
          ),
          const SizedBox(height: 14),
          _field(
            label: 'Location',
            hint: 'City, region, or headquarters',
            icon: Icons.location_on_outlined,
            controller: _locationController,
          ),
          const SizedBox(height: 14),
          _field(
            label: 'Website',
            hint: 'https://www.yourcompany.com',
            icon: Icons.language_rounded,
            controller: _websiteController,
            keyboardType: TextInputType.url,
            validator: (value) {
              final trimmed = (value ?? '').trim();
              if (trimmed.isEmpty) {
                return null;
              }
              if (trimmed.contains(' ')) {
                return 'Website cannot contain spaces.';
              }
              return _websiteUri(trimmed) == null
                  ? 'Enter a valid website.'
                  : null;
            },
          ),
        ],
      ),
    );
  }

  Widget _panel({
    required String title,
    required String subtitle,
    required IconData icon,
    required Widget child,
  }) {
    return SettingsPanel(
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SettingsIconBox(
                icon: icon,
                color: CompanyDashboardPalette.primary,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: SettingsFlowTheme.sectionTitle()),
                    const SizedBox(height: 4),
                    Text(subtitle, style: SettingsFlowTheme.caption()),
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

  Widget _field({
    required String label,
    required String hint,
    required IconData icon,
    required TextEditingController controller,
    TextInputType keyboardType = TextInputType.text,
    int maxLines = 1,
    String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: SettingsFlowTheme.cardTitle()),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          maxLines: maxLines,
          validator: validator,
          style: AppTypography.product(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: CompanyDashboardPalette.textPrimary,
          ),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: SettingsFlowTheme.caption(),
            prefixIcon: Icon(
              icon,
              color: CompanyDashboardPalette.primary.withValues(alpha: 0.82),
            ),
            filled: true,
            fillColor: SettingsFlowPalette.surface,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 16,
            ),
            border: OutlineInputBorder(
              borderRadius: SettingsFlowTheme.radius(18),
              borderSide: BorderSide(color: SettingsFlowPalette.border),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: SettingsFlowTheme.radius(18),
              borderSide: BorderSide(color: SettingsFlowPalette.border),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: SettingsFlowTheme.radius(18),
              borderSide: BorderSide(
                color: CompanyDashboardPalette.primary,
                width: 1.4,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildLogoSection(UserModel user) {
    final hasLogo = (user.logo ?? '').trim().isNotEmpty;
    return _panel(
      title: 'Logo & Visual Identity',
      subtitle:
          'A strong logo or company photo makes the profile feel more polished and recognizable.',
      icon: Icons.image_outlined,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: SettingsFlowPalette.background,
          borderRadius: SettingsFlowTheme.radius(22),
          border: Border.all(color: SettingsFlowPalette.border),
        ),
        child: Column(
          children: [
            ProfileAvatar(user: user, radius: 42),
            const SizedBox(height: 12),
            Text(
              hasLogo
                  ? 'Your current company visual is live.'
                  : 'Add a logo to make your company profile feel complete.',
              style: SettingsFlowTheme.body(),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 6),
            Text(
              'Accepted formats: JPG, PNG, or WebP. Maximum size: 5 MB.',
              style: SettingsFlowTheme.caption(),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            SettingsButtonGroup(
              children: [
                OutlinedButton.icon(
                  onPressed: _uploadingLogo ? null : _pickAndUploadLogo,
                  icon: _uploadingLogo
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.upload_outlined, size: 18),
                  label: Text(
                    _uploadingLogo
                        ? 'Uploading...'
                        : hasLogo
                        ? 'Replace Logo'
                        : 'Upload Logo',
                    style: AppTypography.product(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size.fromHeight(50),
                    foregroundColor: CompanyDashboardPalette.primary,
                    side: BorderSide(color: CompanyDashboardPalette.primary),
                    shape: RoundedRectangleBorder(
                      borderRadius: SettingsFlowTheme.radius(18),
                    ),
                  ),
                ),
                if (hasLogo)
                  OutlinedButton.icon(
                    onPressed: _uploadingLogo ? null : _removeLogo,
                    icon: const Icon(Icons.delete_outline_rounded, size: 18),
                    label: Text(
                      'Remove Logo',
                      style: AppTypography.product(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size.fromHeight(50),
                      foregroundColor: SettingsFlowPalette.error,
                      side: BorderSide(color: SettingsFlowPalette.error),
                      shape: RoundedRectangleBorder(
                        borderRadius: SettingsFlowTheme.radius(18),
                      ),
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRegisterSection(UserModel user) {
    final selectedFile = _commercialRegisterFile;
    final uploadedAt = user.commercialRegisterUploadedAt;
    final uploadedAtLabel = uploadedAt == null
        ? 'Not available'
        : DateFormat('MMM d, yyyy').format(uploadedAt.toDate());

    return _panel(
      title: 'Commercial Register',
      subtitle:
          'Keep a current verification document attached to maintain a trustworthy company profile.',
      icon: Icons.verified_user_outlined,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (selectedFile != null)
            _documentCard(
              title: selectedFile.name,
              subtitle:
                  '${(selectedFile.size / (1024 * 1024)).toStringAsFixed(2)} MB selected',
              primaryLabel: 'Replace',
              primaryAction: _pickCommercialRegister,
            )
          else if (user.hasCommercialRegister)
            _documentCard(
              title: user.commercialRegisterFileName.trim().isNotEmpty
                  ? user.commercialRegisterFileName.trim()
                  : 'Document uploaded',
              subtitle: 'Uploaded: $uploadedAtLabel',
              primaryLabel: 'Replace',
              primaryAction: _pickCommercialRegister,
              secondaryLabel: 'View',
              secondaryAction: () =>
                  _openCommercialRegister(companyId: user.uid),
            )
          else ...[
            SettingsInfoBanner(
              icon: Icons.upload_file_outlined,
              title: 'No verification document uploaded yet',
              message:
                  'Upload a PDF, JPG, or PNG document up to 10 MB to complete this part of the profile.',
              color: CompanyDashboardPalette.accent,
            ),
            const SizedBox(height: 14),
            SettingsPrimaryButton(
              label: 'Upload Document',
              icon: Icons.upload_file_outlined,
              backgroundColor: CompanyDashboardPalette.accent,
              onPressed: _pickCommercialRegister,
            ),
          ],
          if (_commercialRegisterError != null) ...[
            const SizedBox(height: 12),
            Text(
              _commercialRegisterError!,
              style: AppTypography.product(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: SettingsFlowPalette.error,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _documentCard({
    required String title,
    required String subtitle,
    required String primaryLabel,
    required VoidCallback primaryAction,
    String? secondaryLabel,
    VoidCallback? secondaryAction,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: SettingsFlowPalette.background,
        borderRadius: SettingsFlowTheme.radius(22),
        border: Border.all(color: SettingsFlowPalette.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SettingsIconBox(
                icon: Icons.insert_drive_file_outlined,
                color: CompanyDashboardPalette.primary,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: SettingsFlowTheme.cardTitle()),
                    const SizedBox(height: 4),
                    Text(subtitle, style: SettingsFlowTheme.caption()),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          SettingsButtonGroup(
            children: [
              if (secondaryLabel != null && secondaryAction != null)
                SettingsSecondaryButton(
                  label: secondaryLabel,
                  icon: Icons.visibility_outlined,
                  color: CompanyDashboardPalette.primary,
                  onPressed: secondaryAction,
                ),
              SettingsSecondaryButton(
                label: primaryLabel,
                icon: Icons.upload_file_outlined,
                color: CompanyDashboardPalette.accent,
                onPressed: primaryAction,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Uri? _websiteUri(String rawValue) {
    final trimmed = rawValue.trim();
    if (trimmed.isEmpty) {
      return null;
    }
    final normalized = trimmed.contains('://') ? trimmed : 'https://$trimmed';
    return Uri.tryParse(normalized);
  }

  Future<void> _pickAndUploadLogo() async {
    final authProvider = context.read<AuthProvider>();
    final companyProvider = context.read<CompanyProvider>();
    final user = authProvider.userModel;
    if (user == null) {
      return;
    }

    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['jpg', 'jpeg', 'png', 'webp'],
      withData: true,
    );
    if (result == null || result.files.isEmpty) {
      return;
    }

    final file = result.files.single;
    if (file.size > 5 * 1024 * 1024) {
      if (!mounted) {
        return;
      }
      context.showAppSnackBar(
        'Choose an image smaller than 5 MB.',
        title: 'Upload unavailable',
        type: AppFeedbackType.warning,
      );
      return;
    }

    setState(() => _uploadingLogo = true);
    try {
      final error = await companyProvider.uploadCompanyLogo(
        uid: user.uid,
        fileName: file.name,
        filePath: file.path ?? '',
        fileBytes: file.bytes,
      );
      if (!mounted) {
        return;
      }
      if (error != null) {
        context.showAppSnackBar(
          error,
          title: 'Upload unavailable',
          type: AppFeedbackType.error,
        );
        return;
      }
      await authProvider.loadCurrentUser();
      if (mounted) {
        context.showAppSnackBar(
          'Company logo removed.',
          title: 'Logo removed',
          type: AppFeedbackType.removed,
          icon: Icons.delete_outline_rounded,
        );
      }
    } finally {
      if (mounted) {
        setState(() => _uploadingLogo = false);
      }
    }
  }

  Future<void> _removeLogo() async {
    final authProvider = context.read<AuthProvider>();
    final user = authProvider.userModel;
    if (user == null || _uploadingLogo) {
      return;
    }

    setState(() => _uploadingLogo = true);
    try {
      final error = await context.read<CompanyProvider>().removeCompanyLogo(
        user.uid,
      );
      if (!mounted) {
        return;
      }
      if (error != null) {
        context.showAppSnackBar(
          error,
          title: 'Update unavailable',
          type: AppFeedbackType.error,
        );
        return;
      }
      await authProvider.loadCurrentUser();
    } finally {
      if (mounted) {
        setState(() => _uploadingLogo = false);
      }
    }
  }

  Future<void> _pickCommercialRegister() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf', 'png', 'jpg', 'jpeg'],
      withData: true,
    );
    if (result == null || result.files.isEmpty) {
      return;
    }

    final file = result.files.single;
    final validationError = DocumentUploadValidator.validateCommercialRegister(
      fileName: file.name,
      sizeInBytes: file.size,
    );
    setState(() {
      _commercialRegisterFile = file;
      _commercialRegisterError = validationError;
    });
  }

  Future<void> _save() async {
    final form = _formKey.currentState;
    if (form == null || !form.validate()) {
      return;
    }

    setState(() => _saving = true);

    final user = context.read<AuthProvider>().userModel;
    if (user == null) {
      setState(() => _saving = false);
      return;
    }

    final selectedFile = _commercialRegisterFile;
    final commercialRegisterError = selectedFile != null
        ? DocumentUploadValidator.validateCommercialRegister(
            fileName: selectedFile.name,
            sizeInBytes: selectedFile.size,
          )
        : (!user.hasCommercialRegister
              ? 'Commercial register is required for company profiles.'
              : null);

    if (commercialRegisterError != null) {
      setState(() {
        _saving = false;
        _commercialRegisterError = commercialRegisterError;
      });
      return;
    }

    final data = {
      'companyName': _companyNameController.text.trim(),
      'sector': _sectorController.text.trim(),
      'description': _descriptionController.text.trim(),
      'phone': _phoneController.text.trim(),
      'location': _locationController.text.trim(),
      'website': _websiteController.text.trim(),
    };

    final error = await context.read<CompanyProvider>().updateProfile(
      user.uid,
      data,
      commercialRegisterFilePath: selectedFile?.path ?? '',
      commercialRegisterFileName: selectedFile?.name ?? '',
      commercialRegisterBytes: selectedFile?.bytes,
    );

    if (!mounted) {
      return;
    }

    setState(() => _saving = false);

    if (error != null) {
      context.showAppSnackBar(
        error,
        title: 'Update unavailable',
        type: AppFeedbackType.error,
      );
      return;
    }

    await context.read<AuthProvider>().loadCurrentUser();
    if (!mounted) {
      return;
    }
    Navigator.pop(context);
  }

  Future<void> _openCommercialRegister({
    required String companyId,
    bool download = false,
  }) async {
    try {
      final document = await DocumentAccessService()
          .getCompanyCommercialRegister(companyId: companyId);
      final uri = Uri.tryParse(
        download ? document.downloadUrl : document.viewUrl,
      );
      if (uri == null) {
        throw Exception('File unavailable.');
      }
      final launched = await launchUrl(
        uri,
        mode: LaunchMode.platformDefault,
        webOnlyWindowName: '_blank',
      );
      if (!launched && mounted) {
        context.showAppSnackBar(
          'We couldn\'t open the document right now.',
          title: 'Document unavailable',
          type: AppFeedbackType.error,
        );
      }
    } catch (error) {
      if (!mounted) {
        return;
      }
      context.showAppSnackBar(
        _documentErrorMessage(error),
        title: 'Document unavailable',
        type: AppFeedbackType.error,
      );
    }
  }

  String _documentErrorMessage(Object error) {
    final message = error.toString().toLowerCase();
    if (message.contains('permission') || message.contains('403')) {
      return 'Permission denied while opening the document.';
    }
    if (message.contains('404') || message.contains('not found')) {
      return 'The requested document is no longer available.';
    }
    return 'We couldn\'t open the document right now.';
  }
}

class _CompanySettingsAppBar extends StatelessWidget
    implements PreferredSizeWidget {
  final String title;

  const _CompanySettingsAppBar({required this.title});

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    final canPop = Navigator.of(context).canPop();

    return AppBar(
      automaticallyImplyLeading: false,
      centerTitle: false,
      backgroundColor: SettingsFlowPalette.background,
      surfaceTintColor: Colors.transparent,
      scrolledUnderElevation: 0,
      elevation: 0,
      leading: canPop
          ? IconButton(
              onPressed: () => Navigator.maybePop(context),
              icon: Icon(
                Icons.arrow_back_ios_new_rounded,
                color: SettingsFlowPalette.textPrimary,
              ),
            )
          : null,
      title: Text(title, style: SettingsFlowTheme.appBarTitle()),
    );
  }
}

class _BackdropOrb extends StatelessWidget {
  final double size;
  final Color color;

  const _BackdropOrb(this.size, this.color);

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

class _VerifiedNameBadge extends StatelessWidget {
  const _VerifiedNameBadge();

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: 'Approved company',
      child: Semantics(
        label: 'Approved company',
        child: Container(
          width: 23,
          height: 23,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.18),
            borderRadius: SettingsFlowTheme.radius(999),
            border: Border.all(color: Colors.white.withValues(alpha: 0.24)),
          ),
          child: Icon(
            Icons.verified_rounded,
            size: 16,
            color: CompanyDashboardPalette.success,
          ),
        ),
      ),
    );
  }
}

class _HeroActionButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback onPressed;
  final bool filled;

  const _HeroActionButton({
    required this.label,
    required this.icon,
    required this.onPressed,
    this.filled = false,
  });

  @override
  Widget build(BuildContext context) {
    final style = AppTypography.product(
      fontSize: 13,
      fontWeight: FontWeight.w600,
    );
    if (filled) {
      return ElevatedButton.icon(
        onPressed: onPressed,
        icon: Icon(icon, size: 18),
        label: Text(label, style: style),
        style: ElevatedButton.styleFrom(
          minimumSize: const Size.fromHeight(50),
          elevation: 0,
          backgroundColor: SettingsFlowPalette.surface,
          foregroundColor: CompanyDashboardPalette.primaryDark,
          shape: RoundedRectangleBorder(
            borderRadius: SettingsFlowTheme.radius(18),
          ),
        ),
      );
    }
    return OutlinedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, size: 18),
      label: Text(label, style: style),
      style: OutlinedButton.styleFrom(
        minimumSize: const Size.fromHeight(50),
        foregroundColor: Colors.white,
        side: BorderSide(color: Colors.white.withValues(alpha: 0.28)),
        backgroundColor: Colors.white.withValues(alpha: 0.06),
        shape: RoundedRectangleBorder(
          borderRadius: SettingsFlowTheme.radius(18),
        ),
      ),
    );
  }
}

class _DetailTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color accentColor;
  final VoidCallback? onTap;

  const _DetailTile({
    required this.icon,
    required this.label,
    required this.value,
    required this.accentColor,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: SettingsFlowTheme.radius(24),
      child: Ink(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: SettingsFlowPalette.surface,
          borderRadius: SettingsFlowTheme.radius(24),
          border: Border.all(color: SettingsFlowPalette.border),
          boxShadow: SettingsFlowTheme.softShadow(0.05),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SettingsIconBox(
              icon: icon,
              color: accentColor,
              backgroundColor: accentColor.withValues(alpha: 0.12),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label, style: SettingsFlowTheme.micro(accentColor)),
                  const SizedBox(height: 6),
                  Text(value, style: SettingsFlowTheme.body()),
                ],
              ),
            ),
            if (onTap != null)
              Icon(
                Icons.open_in_new_rounded,
                size: 18,
                color: accentColor.withValues(alpha: 0.72),
              ),
          ],
        ),
      ),
    );
  }
}

class _CompanyMissingChip extends StatelessWidget {
  final _CompanyMissingItem item;

  const _CompanyMissingChip({required this.item});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 8),
      decoration: BoxDecoration(
        color: item.color.withValues(alpha: AppColors.isDark ? 0.18 : 0.10),
        borderRadius: SettingsFlowTheme.radius(999),
        border: Border.all(
          color: item.color.withValues(alpha: AppColors.isDark ? 0.30 : 0.18),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(item.icon, size: 14, color: item.color),
          const SizedBox(width: 7),
          Text(
            item.label,
            style: AppTypography.product(
              fontSize: 11.5,
              fontWeight: FontWeight.w700,
              color: item.color,
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color backgroundColor;
  final Color foregroundColor;

  const _StatusBadge({
    required this.label,
    required this.icon,
    required this.backgroundColor,
    required this.foregroundColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: SettingsFlowTheme.radius(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: foregroundColor),
          const SizedBox(width: 6),
          Text(
            label,
            style: AppTypography.product(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: foregroundColor,
            ),
          ),
        ],
      ),
    );
  }
}

class _CompanyMissingItem {
  final String label;
  final IconData icon;
  final Color color;

  const _CompanyMissingItem({
    required this.label,
    required this.icon,
    required this.color,
  });
}
