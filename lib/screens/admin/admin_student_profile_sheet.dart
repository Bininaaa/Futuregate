import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../l10n/generated/app_localizations.dart';
import '../../models/cv_model.dart';
import '../../models/student_application_item_model.dart';
import '../../models/user_model.dart';
import '../../services/application_service.dart';
import '../../services/cv_service.dart';
import '../../services/document_access_service.dart';
import '../../utils/admin_palette.dart';
import '../../utils/application_status.dart';
import '../../utils/display_text.dart';
import '../../widgets/admin/admin_ui.dart';
import '../../widgets/profile_avatar.dart';
import '../../widgets/shared/app_feedback.dart';

Future<void> showAdminStudentProfileSheet(
  BuildContext context, {
  required UserModel user,
}) {
  return showModalBottomSheet<void>(
    context: context,
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
    ),
    builder: (_) => _AdminStudentProfileSheet(user: user),
  );
}

Future<void> showAdminStudentApplicationsSheet(
  BuildContext context, {
  required String studentId,
  required String studentName,
}) {
  return showModalBottomSheet<void>(
    context: context,
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
    ),
    builder: (_) => _AdminStudentApplicationsSheet(
      studentId: studentId,
      studentName: studentName,
    ),
  );
}

class _AdminStudentProfileSheet extends StatefulWidget {
  final UserModel user;

  const _AdminStudentProfileSheet({required this.user});

  @override
  State<_AdminStudentProfileSheet> createState() =>
      _AdminStudentProfileSheetState();
}

class _AdminStudentProfileSheetState extends State<_AdminStudentProfileSheet> {
  final CvService _cvService = CvService();
  final ApplicationService _applicationService = ApplicationService();
  final DocumentAccessService _documentAccessService = DocumentAccessService();

  late Future<CvModel?> _cvFuture;
  late Future<List<StudentApplicationItemModel>> _applicationsFuture;

  AppLocalizations get _l10n => AppLocalizations.of(context)!;

  @override
  void initState() {
    super.initState();
    _cvFuture = _cvService.getCvByStudentId(widget.user.uid);
    _applicationsFuture = _applicationService.getSubmittedApplications(
      widget.user.uid,
      onlyVisibleOpportunities: false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = _l10n;
    return DraggableScrollableSheet(
      initialChildSize: 0.78,
      minChildSize: 0.46,
      maxChildSize: 0.94,
      expand: false,
      builder: (context, scrollController) {
        return ClipRRect(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
          child: Material(
            color: AdminPalette.background,
            child: ListView(
              controller: scrollController,
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
              children: [
                _buildSheetHandle(),
                const SizedBox(height: 16),
                _StudentHeroCard(user: widget.user),
                const SizedBox(height: 18),
                AdminSectionHeader(
                  eyebrow: l10n.uiProfile,
                  title: l10n.uiStudentDetails,
                  subtitle: l10n
                      .uiReviewIdentityAcademicDetailsCvDocumentsAndVisibleSubmittedApplicationsInOnePlace,
                ),
                const SizedBox(height: 12),
                _DetailRow(
                  icon: Icons.email_outlined,
                  label: l10n.uiEmail,
                  value: widget.user.email,
                  preserveValueFormatting: true,
                  singleLineValue: true,
                ),
                _DetailRow(
                  icon: Icons.phone_outlined,
                  label: l10n.uiPhone,
                  value: widget.user.phone,
                  placeholder: l10n.uiNotProvided,
                  preserveValueFormatting: true,
                ),
                _DetailRow(
                  icon: Icons.location_on_outlined,
                  label: l10n.uiLocation,
                  value: widget.user.location,
                  placeholder: l10n.uiNotProvided,
                ),
                _DetailRow(
                  icon: Icons.school_outlined,
                  label: l10n.uiAcademicLevel,
                  value: widget.user.academicLevel,
                  placeholder: l10n.uiNotProvided,
                ),
                _DetailRow(
                  icon: Icons.account_balance_outlined,
                  label: l10n.uiUniversity,
                  value: widget.user.university,
                  placeholder: l10n.uiNotProvided,
                ),
                _DetailRow(
                  icon: Icons.subject_outlined,
                  label: l10n.uiFieldOfStudy,
                  value: widget.user.fieldOfStudy,
                  placeholder: l10n.uiNotProvided,
                ),
                if ((widget.user.academicLevel ?? '').trim().toLowerCase() ==
                    'doctorat') ...[
                  _DetailRow(
                    icon: Icons.science_outlined,
                    label: l10n.uiResearchTopic,
                    value: widget.user.researchTopic,
                    placeholder: l10n.uiNotProvided,
                  ),
                  _DetailRow(
                    icon: Icons.biotech_outlined,
                    label: l10n.uiLaboratory,
                    value: widget.user.laboratory,
                    placeholder: l10n.uiNotProvided,
                  ),
                  _DetailRow(
                    icon: Icons.person_outline_rounded,
                    label: l10n.uiSupervisor,
                    value: widget.user.supervisor,
                    placeholder: l10n.uiNotProvided,
                  ),
                  _DetailRow(
                    icon: Icons.category_outlined,
                    label: l10n.uiResearchDomain,
                    value: widget.user.researchDomain,
                    placeholder: l10n.uiNotProvided,
                  ),
                ],
                if ((widget.user.bio ?? '').trim().isNotEmpty)
                  _LongFormCard(
                    icon: Icons.person_outline_rounded,
                    title: l10n.uiBio,
                    value: widget.user.bio!.trim(),
                  ),
                const SizedBox(height: 6),
                FutureBuilder<CvModel?>(
                  future: _cvFuture,
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Padding(
                        padding: EdgeInsets.symmetric(vertical: 12),
                        child: LinearProgressIndicator(),
                      );
                    }

                    return _buildStudentCvSection(snapshot.data);
                  },
                ),
                const SizedBox(height: 6),
                FutureBuilder<List<StudentApplicationItemModel>>(
                  future: _applicationsFuture,
                  builder: (context, snapshot) {
                    return _buildApplicationsSection(snapshot);
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildStudentCvSection(CvModel? cv) {
    final l10n = _l10n;
    return AdminSurface(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(16),
      radius: 20,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AdminSectionHeader(
            eyebrow: l10n.uiDocuments,
            title: l10n.uiStudentCv,
          ),
          const SizedBox(height: 14),
          _SectionCopy(
            title: l10n.uiPrimaryCv,
            value: cv == null
                ? l10n.uiNoCvHasBeenCreatedForThisStudent
                : cv.hasUploadedCv
                ? l10n.uiPrimaryCvValue(cv.uploadedCvDisplayName)
                : l10n.uiPrimaryCvNotUploaded,
          ),
          const SizedBox(height: 6),
          _SectionCopy(
            title: l10n.uiBuiltCv,
            value: cv == null
                ? l10n.uiBuiltCvUnavailable
                : cv.hasExportedPdf
                ? l10n.uiBuiltCvPdfAvailable
                : cv.hasBuilderContent
                ? l10n.uiBuiltCvInformationAvailable
                : l10n.uiBuiltCvUnavailable,
          ),
          if (cv != null && cv.hasUploadedCv) ...[
            const SizedBox(height: 12),
            _AdaptiveActionGroup(
              buttons: [
                _DocumentButton(
                  label: l10n.uiViewCv,
                  icon: Icons.visibility_outlined,
                  onPressed: cv.isUploadedCvPdf
                      ? () => _openUserCvDocument(
                          widget.user.uid,
                          variant: 'primary',
                          requirePdf: true,
                        )
                      : null,
                  color: AdminPalette.accent,
                ),
                _DocumentButton(
                  label: l10n.uiDownloadCv,
                  icon: Icons.download_outlined,
                  onPressed: () => _openUserCvDocument(
                    widget.user.uid,
                    variant: 'primary',
                    download: true,
                  ),
                  color: AdminPalette.accent,
                  outlined: true,
                ),
              ],
            ),
            if (!cv.isUploadedCvPdf) ...[
              const SizedBox(height: 10),
              Text(
                l10n.uiTheUploadedFileIsNotAValidPdf,
                style: TextStyle(
                  fontSize: 12,
                  color: AdminPalette.warning,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ],
          if (cv != null && cv.hasExportedPdf) ...[
            const SizedBox(height: 10),
            _AdaptiveActionGroup(
              buttons: [
                _DocumentButton(
                  label: l10n.uiViewBuiltCv,
                  icon: Icons.picture_as_pdf_outlined,
                  onPressed: () => _openUserCvDocument(
                    widget.user.uid,
                    variant: 'built',
                    requirePdf: true,
                  ),
                  color: AdminPalette.primaryDark,
                ),
                _DocumentButton(
                  label: l10n.uiDownloadBuiltCv,
                  icon: Icons.download_outlined,
                  onPressed: () => _openUserCvDocument(
                    widget.user.uid,
                    variant: 'built',
                    download: true,
                  ),
                  color: AdminPalette.primaryDark,
                  outlined: true,
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildApplicationsSection(
    AsyncSnapshot<List<StudentApplicationItemModel>> snapshot,
  ) {
    final items = snapshot.data ?? const <StudentApplicationItemModel>[];
    final countLabel = switch (snapshot.connectionState) {
      ConnectionState.waiting => 'Loading application history...',
      _ when snapshot.hasError =>
        'Application history is unavailable right now.',
      _ when items.isEmpty =>
        'No applications have been submitted by this student yet.',
      _ when items.length == 1 => '1 submitted application',
      _ => '${items.length} submitted applications',
    };

    return AdminSurface(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(16),
      radius: 20,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AdminSectionHeader(title: _l10n.uiStudentApplications),
          const SizedBox(height: 14),
          _SectionCopy(title: 'Application history', value: countLabel),
          if (snapshot.hasError) ...[
            const SizedBox(height: 10),
            Text(
              'We could not load the application summary right now, but you can still open the full history and try again.',
              style: TextStyle(
                fontSize: 12,
                height: 1.45,
                color: AdminPalette.warning,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: _DocumentButton(
              label: items.isEmpty
                  ? _l10n.uiViewAllApps
                  : 'View All Apps (${items.length})',
              icon: Icons.assignment_outlined,
              onPressed: () => showAdminStudentApplicationsSheet(
                context,
                studentId: widget.user.uid,
                studentName: widget.user.fullName,
              ),
              color: AdminPalette.activity,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _openUserCvDocument(
    String userId, {
    required String variant,
    bool download = false,
    bool requirePdf = false,
  }) async {
    final l10n = AppLocalizations.of(context)!;
    try {
      final document = await _documentAccessService.getUserCvDocument(
        userId: userId,
        variant: variant,
      );
      if (!mounted) {
        return;
      }

      if (requirePdf && !document.isPdf) {
        context.showAppSnackBar(
          l10n.uiThisDocumentIsNotAValidPdfFile,
          title: l10n.uiPreviewUnavailable,
          type: AppFeedbackType.warning,
        );
        return;
      }

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
      if (!mounted) {
        return;
      }

      if (!launched) {
        context.showAppSnackBar(
          l10n.uiCouldNotOpenTheDocumentRightNow,
          title: l10n.uiDocumentUnavailable,
          type: AppFeedbackType.error,
        );
      }
    } catch (error) {
      if (!mounted) {
        return;
      }

      context.showAppSnackBar(
        _documentErrorMessage(error),
        title: l10n.uiDocumentUnavailable,
        type: AppFeedbackType.error,
      );
    }
  }

  String _documentErrorMessage(Object error) {
    final message = error.toString().toLowerCase();
    if (message.contains('permission') || message.contains('403')) {
      return _l10n.uiPermissionDeniedWhileOpeningTheDocument;
    }
    if (message.contains('404') || message.contains('not found')) {
      return _l10n.uiTheRequestedDocumentIsNoLongerAvailable;
    }

    return _l10n.uiCouldNotOpenTheDocumentRightNow;
  }
}

class _AdminStudentApplicationsSheet extends StatefulWidget {
  final String studentId;
  final String studentName;

  const _AdminStudentApplicationsSheet({
    required this.studentId,
    required this.studentName,
  });

  @override
  State<_AdminStudentApplicationsSheet> createState() =>
      _AdminStudentApplicationsSheetState();
}

class _AdminStudentApplicationsSheetState
    extends State<_AdminStudentApplicationsSheet> {
  final ApplicationService _applicationService = ApplicationService();

  late Future<List<StudentApplicationItemModel>> _applicationsFuture;

  @override
  void initState() {
    super.initState();
    _applicationsFuture = _loadApplications();
  }

  Future<List<StudentApplicationItemModel>> _loadApplications() {
    return _applicationService.getSubmittedApplications(
      widget.studentId,
      onlyVisibleOpportunities: false,
    );
  }

  void _retry() {
    setState(() {
      _applicationsFuture = _loadApplications();
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return DraggableScrollableSheet(
      initialChildSize: 0.72,
      minChildSize: 0.4,
      maxChildSize: 0.94,
      expand: false,
      builder: (context, scrollController) {
        return ClipRRect(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
          child: Material(
            color: AdminPalette.background,
            child: FutureBuilder<List<StudentApplicationItemModel>>(
              future: _applicationsFuture,
              builder: (context, snapshot) {
                final items =
                    snapshot.data ?? const <StudentApplicationItemModel>[];

                return ListView(
                  controller: scrollController,
                  padding: const EdgeInsets.fromLTRB(16, 10, 16, 20),
                  children: [
                    _buildSheetHandle(),
                    const SizedBox(height: 12),
                    AdminSurface(
                      radius: 20,
                      gradient: AdminPalette.heroGradient(
                        AdminPalette.activity,
                      ),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.12),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(
                            Icons.assignment_outlined,
                            color: Colors.white,
                            size: 26,
                          ),
                          const SizedBox(height: 10),
                          Text(
                            widget.studentName.trim().isEmpty
                                ? l10n.uiStudentApplications
                                : l10n.uiApplicationsForValue(
                                    widget.studentName,
                                  ),
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            snapshot.connectionState == ConnectionState.waiting
                                ? 'Loading application history...'
                                : items.isEmpty
                                ? 'No submitted applications yet.'
                                : items.length == 1
                                ? '1 submitted application available for review'
                                : '${items.length} submitted applications available for review',
                            style: const TextStyle(
                              fontSize: 12.5,
                              color: Colors.white70,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 10),
                    if (snapshot.connectionState == ConnectionState.waiting)
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 28),
                        child: Center(child: CircularProgressIndicator()),
                      )
                    else if (snapshot.hasError)
                      AdminEmptyState(
                        icon: Icons.assignment_late_outlined,
                        title: l10n.uiApplicationHistoryUnavailable,
                        message:
                            'We could not load this student\'s full application history right now.',
                        action: FilledButton.icon(
                          onPressed: _retry,
                          icon: const Icon(Icons.refresh_rounded),
                          label: Text(AppLocalizations.of(context)!.retryLabel),
                        ),
                      )
                    else if (items.isEmpty)
                      const AdminEmptyState(
                        icon: Icons.assignment_turned_in_outlined,
                        title: 'No applications yet',
                        message:
                            'This student has not submitted any applications yet.',
                      )
                    else
                      ...items.map(_buildApplicationCard),
                  ],
                );
              },
            ),
          ),
        );
      },
    );
  }

  Widget _buildApplicationCard(StudentApplicationItemModel item) {
    final l10n = AppLocalizations.of(context)!;
    final statusColor = _statusColor(item.status);
    final opportunityStateLabel = _opportunityStateLabel(item);
    final opportunityStateColor = _opportunityStateColor(item);
    final appliedLabel = item.appliedAt == null
        ? l10n.uiAppliedDateUnavailable
        : l10n.uiAppliedValue(
            DateFormat('MMM d, yyyy').format(item.appliedAt!),
          );

    return AdminSurface(
      margin: const EdgeInsets.only(bottom: 10),
      padding: EdgeInsets.zero,
      radius: 20,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: AdminPalette.activity.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(
                Icons.assignment_outlined,
                color: AdminPalette.activity,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.title,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: AdminPalette.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    item.companyName,
                    style: TextStyle(
                      fontSize: 12.2,
                      color: AdminPalette.textSecondary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: [
                      AdminPill(
                        label: ApplicationStatus.label(item.status, l10n),
                        color: statusColor,
                        icon: Icons.flag_outlined,
                      ),
                      AdminPill(
                        label: item.location,
                        color: AdminPalette.info,
                        icon: Icons.location_on_outlined,
                      ),
                      if (opportunityStateLabel != null)
                        AdminPill(
                          label: opportunityStateLabel,
                          color: opportunityStateColor,
                          icon: Icons.visibility_off_outlined,
                        ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Text(
                    appliedLabel,
                    style: TextStyle(
                      fontSize: 11.8,
                      color: AdminPalette.textMuted,
                      fontWeight: FontWeight.w600,
                    ),
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

class _StudentHeroCard extends StatelessWidget {
  final UserModel user;

  const _StudentHeroCard({required this.user});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final academicLevel = (user.academicLevel ?? '').trim();
    final university = (user.university ?? '').trim();

    return AdminSurface(
      radius: 24,
      padding: const EdgeInsets.fromLTRB(18, 20, 18, 18),
      gradient: AdminPalette.heroGradient(AdminPalette.info),
      border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
      child: Column(
        children: [
          ProfileAvatar(user: user, radius: 42),
          const SizedBox(height: 14),
          Text(
            user.fullName,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            university.isNotEmpty
                ? university
                : l10n.uiStudentProfileAvailableForAdminReview,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 12.8,
              color: Colors.white70,
              height: 1.45,
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            alignment: WrapAlignment.center,
            spacing: 8,
            runSpacing: 8,
            children: [
              AdminPill(
                label: l10n.uiStudent,
                color: Colors.white,
                icon: Icons.school_outlined,
              ),
              if (academicLevel.isNotEmpty)
                AdminPill(
                  label: DisplayText.capitalizeLeadingLabel(academicLevel),
                  color: Colors.white,
                  icon: Icons.workspace_premium_outlined,
                ),
              AdminPill(
                label: user.isActive ? l10n.uiActive : l10n.uiBlocked,
                color: Colors.white,
                icon: user.isActive
                    ? Icons.check_circle_outline_rounded
                    : Icons.block_outlined,
              ),
            ],
          ),
          const SizedBox(height: 12),
          _SingleLineText(
            user.email,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 13, color: Colors.white70),
          ),
        ],
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String? value;
  final String? placeholder;
  final bool preserveValueFormatting;
  final bool singleLineValue;

  const _DetailRow({
    required this.icon,
    required this.label,
    required this.value,
    this.placeholder,
    this.preserveValueFormatting = false,
    this.singleLineValue = false,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final trimmedValue = (value ?? '').trim();
    final displayValue = trimmedValue.isNotEmpty
        ? (preserveValueFormatting
              ? trimmedValue
              : DisplayText.capitalizeLeadingLabel(trimmedValue))
        : (placeholder ?? l10n.uiNotProvided);
    final valueStyle = TextStyle(
      fontSize: trimmedValue.isEmpty ? 13.2 : 14,
      height: 1.4,
      color: trimmedValue.isEmpty
          ? AdminPalette.textMuted
          : AdminPalette.textPrimary,
      fontWeight: trimmedValue.isEmpty ? FontWeight.w500 : FontWeight.w600,
    );

    return AdminSurface(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      radius: 18,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AdminPalette.primarySoft,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, size: 20, color: AdminPalette.primary),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 11.5,
                    color: AdminPalette.textMuted,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                singleLineValue
                    ? _SingleLineText(displayValue, style: valueStyle)
                    : Text(displayValue, style: valueStyle),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SingleLineText extends StatelessWidget {
  final String value;
  final TextStyle style;
  final TextAlign textAlign;

  const _SingleLineText(
    this.value, {
    required this.style,
    this.textAlign = TextAlign.start,
  });

  @override
  Widget build(BuildContext context) {
    final alignment = switch (textAlign) {
      TextAlign.center => Alignment.center,
      TextAlign.right => Alignment.centerRight,
      TextAlign.end => Alignment.centerRight,
      _ => Alignment.centerLeft,
    };

    return SizedBox(
      width: double.infinity,
      child: FittedBox(
        fit: BoxFit.scaleDown,
        alignment: alignment,
        child: Text(
          value,
          maxLines: 1,
          softWrap: false,
          overflow: TextOverflow.visible,
          textAlign: textAlign,
          style: style,
        ),
      ),
    );
  }
}

class _LongFormCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String value;

  const _LongFormCard({
    required this.icon,
    required this.title,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return AdminSurface(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      radius: 18,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: AdminPalette.primarySoft,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(icon, size: 20, color: AdminPalette.primary),
              ),
              const SizedBox(width: 12),
              Text(
                title,
                style: TextStyle(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w700,
                  color: AdminPalette.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: TextStyle(
              fontSize: 13,
              height: 1.55,
              color: AdminPalette.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionCopy extends StatelessWidget {
  final String title;
  final String value;

  const _SectionCopy({required this.title, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: AdminPalette.textPrimary,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          value,
          style: TextStyle(
            fontSize: 12.5,
            height: 1.5,
            color: AdminPalette.textSecondary,
          ),
        ),
      ],
    );
  }
}

class _AdaptiveActionGroup extends StatelessWidget {
  final List<Widget> buttons;

  const _AdaptiveActionGroup({required this.buttons});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (buttons.isEmpty) {
          return const SizedBox.shrink();
        }

        if (buttons.length == 1) {
          return SizedBox(width: double.infinity, child: buttons.first);
        }

        if (constraints.maxWidth < 440) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              for (var index = 0; index < buttons.length; index++) ...[
                buttons[index],
                if (index < buttons.length - 1) const SizedBox(height: 10),
              ],
            ],
          );
        }

        return Row(
          children: [
            for (var index = 0; index < buttons.length; index++) ...[
              Expanded(child: buttons[index]),
              if (index < buttons.length - 1) const SizedBox(width: 10),
            ],
          ],
        );
      },
    );
  }
}

class _DocumentButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback? onPressed;
  final Color color;
  final bool outlined;

  const _DocumentButton({
    required this.label,
    required this.icon,
    required this.onPressed,
    required this.color,
    this.outlined = false,
  });

  @override
  Widget build(BuildContext context) {
    if (outlined) {
      return OutlinedButton.icon(
        onPressed: onPressed,
        icon: Icon(icon, size: 18),
        label: Text(label),
        style: OutlinedButton.styleFrom(
          foregroundColor: color,
          side: BorderSide(color: color.withValues(alpha: 0.24)),
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 14),
        ),
      );
    }

    return FilledButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, size: 18),
      label: Text(label),
      style: FilledButton.styleFrom(
        backgroundColor: color,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 14),
      ),
    );
  }
}

Widget _buildSheetHandle() {
  return Center(
    child: Container(
      width: 46,
      height: 5,
      decoration: BoxDecoration(
        color: AdminPalette.border,
        borderRadius: BorderRadius.circular(999),
      ),
    ),
  );
}

Color _statusColor(String status) {
  switch (ApplicationStatus.parse(status)) {
    case ApplicationStatus.accepted:
      return AdminPalette.success;
    case ApplicationStatus.rejected:
      return AdminPalette.danger;
    case ApplicationStatus.withdrawn:
      return AdminPalette.textMuted;
    case ApplicationStatus.pending:
    default:
      return AdminPalette.warning;
  }
}

String? _opportunityStateLabel(StudentApplicationItemModel item) {
  final opportunity = item.opportunity;
  if (opportunity == null) {
    return 'Opportunity unavailable';
  }
  if (opportunity.isHidden) {
    return 'Opportunity hidden';
  }
  if (opportunity.effectiveStatus() == 'closed') {
    return 'Opportunity closed';
  }

  return null;
}

Color _opportunityStateColor(StudentApplicationItemModel item) {
  final opportunity = item.opportunity;
  if (opportunity == null) {
    return AdminPalette.danger;
  }
  if (opportunity.isHidden) {
    return AdminPalette.textMuted;
  }
  if (opportunity.effectiveStatus() == 'closed') {
    return AdminPalette.warning;
  }

  return AdminPalette.info;
}
