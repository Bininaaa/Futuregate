import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../models/admin_activity_model.dart';
import '../../models/admin_activity_preview_model.dart';
import '../../models/application_model.dart';
import '../../models/opportunity_model.dart';
import '../../models/project_idea_model.dart';
import '../../models/training_model.dart';
import '../../services/admin_service.dart';
import '../../utils/admin_palette.dart';
import '../../utils/application_status.dart';
import '../../utils/display_text.dart';
import '../../utils/opportunity_metadata.dart';
import '../../utils/opportunity_type.dart';
import 'admin_ui.dart';

class AdminActivityPreviewSheet extends StatefulWidget {
  final AdminActivityModel activity;
  final String manageLabel;
  final VoidCallback onManage;

  const AdminActivityPreviewSheet({
    super.key,
    required this.activity,
    required this.manageLabel,
    required this.onManage,
  });

  @override
  State<AdminActivityPreviewSheet> createState() =>
      _AdminActivityPreviewSheetState();
}

class _AdminActivityPreviewSheetState extends State<AdminActivityPreviewSheet> {
  final AdminService _adminService = AdminService();
  late final Future<AdminActivityPreviewModel?> _previewFuture;

  @override
  void initState() {
    super.initState();
    _previewFuture = _adminService.getActivityPreview(widget.activity);
  }

  @override
  Widget build(BuildContext context) {
    final accentColor = _accentColor(widget.activity.type);
    final horizontalPadding = _sheetHorizontalPadding(context);
    final bottomPadding = 24.0 + MediaQuery.paddingOf(context).bottom;

    return DraggableScrollableSheet(
      initialChildSize: 0.82,
      minChildSize: 0.46,
      maxChildSize: 0.96,
      expand: false,
      builder: (context, scrollController) => SafeArea(
        top: false,
        child: ListView(
          controller: scrollController,
          padding: EdgeInsets.fromLTRB(
            horizontalPadding,
            12,
            horizontalPadding,
            bottomPadding,
          ),
          children: [
            _buildSheetHandle(),
            const SizedBox(height: 16),
            FutureBuilder<AdminActivityPreviewModel?>(
              future: _previewFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState != ConnectionState.done) {
                  return const _LoadingCard();
                }

                final preview = snapshot.data;
                if (snapshot.hasError || preview == null) {
                  return _UnavailableCard(activity: widget.activity);
                }

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ..._buildPreviewSections(preview),
                    const SizedBox(height: 14),
                    _buildManageButton(accentColor),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSheetHandle() {
    return Center(
      child: Container(
        width: 42,
        height: 5,
        decoration: BoxDecoration(
          color: AdminPalette.border,
          borderRadius: BorderRadius.circular(999),
        ),
      ),
    );
  }

  Widget _buildManageButton(Color accentColor) {
    return FilledButton.icon(
      onPressed: () {
        Navigator.of(context).pop();
        widget.onManage();
      },
      icon: const Icon(Icons.tune_rounded),
      label: Text(widget.manageLabel),
      style: FilledButton.styleFrom(
        backgroundColor: accentColor,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(vertical: 15),
      ),
    );
  }

  List<Widget> _buildPreviewSections(AdminActivityPreviewModel preview) {
    switch (widget.activity.type) {
      case 'application':
        return _buildApplicationSections(preview);
      case 'opportunity':
        return _buildOpportunitySections(preview);
      case 'scholarship':
        return _buildScholarshipSections(preview);
      case 'training':
        return _buildTrainingSections(preview);
      case 'project_idea':
      default:
        return _buildProjectIdeaSections(preview);
    }
  }

  List<Widget> _buildApplicationSections(AdminActivityPreviewModel preview) {
    final application = ApplicationModel.fromMap(preview.data);
    final relatedOpportunity = preview.relatedData ?? const <String, dynamic>{};
    final studentName = DisplayText.capitalizeLeadingLabel(
      application.studentName.trim().isNotEmpty
          ? application.studentName
          : widget.activity.actorName,
    );
    final opportunityTitle = DisplayText.capitalizeLeadingLabel(
      (relatedOpportunity['title'] ?? '').toString(),
    );
    final companyName = DisplayText.capitalizeLeadingLabel(
      (relatedOpportunity['companyName'] ?? '').toString(),
    );
    final statusLabel = ApplicationStatus.label(application.status);
    final description = opportunityTitle.isNotEmpty
        ? 'Applied to $opportunityTitle.'
        : 'Application details';

    return [
      _buildDetailHeroCard(
        title: studentName.isNotEmpty ? studentName : 'Application',
        subtitle: companyName.isNotEmpty ? companyName : 'Application',
        icon: Icons.assignment_outlined,
        accentColor: AdminPalette.activity,
        chips: [
          _buildHeroChip(statusLabel, Icons.verified_outlined),
          if (application.appliedAt != null)
            _buildHeroChip(
              _formatShortDate(application.appliedAt),
              Icons.event_outlined,
            ),
        ],
      ),
      const SizedBox(height: 14),
      AdminSurface(
        radius: 20,
        padding: _largePanelPadding(context),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Description',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: AdminPalette.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              description,
              style: const TextStyle(
                fontSize: 13,
                height: 1.5,
                color: AdminPalette.textSecondary,
              ),
            ),
          ],
        ),
      ),
      const SizedBox(height: 14),
      const AdminSectionHeader(
        eyebrow: 'Details',
        title: 'Item Metadata',
        subtitle:
            'Important fields are grouped here in a more readable admin detail layout.',
      ),
      const SizedBox(height: 12),
      ..._buildDetailLineWidgets([
        _PreviewDetailLine('Opportunity', opportunityTitle),
        _PreviewDetailLine('Company', companyName),
        _PreviewDetailLine('Status', statusLabel),
        _PreviewDetailLine('Applied', _formatTimestamp(application.appliedAt)),
      ]),
    ];
  }

  List<Widget> _buildOpportunitySections(AdminActivityPreviewModel preview) {
    final opportunity = OpportunityModel.fromMap(preview.data);
    final opportunityType = OpportunityType.parse(opportunity.type);
    final typeLabel = OpportunityType.label(opportunityType);
    final typeColor = OpportunityType.color(opportunityType);
    final description = DisplayText.capitalizeLeadingLabel(
      opportunity.description,
    );
    final workModeLabel =
        OpportunityMetadata.formatWorkMode(opportunity.workMode) ?? '';
    final employmentLabel =
        OpportunityMetadata.formatEmploymentType(opportunity.employmentType) ??
        '';
    final paidLabel =
        OpportunityMetadata.formatPaidLabel(opportunity.isPaid) ?? '';
    final statusLabel = DisplayText.capitalizeLeadingLabel(opportunity.status);
    final compensationLabel = opportunityType == OpportunityType.sponsoring
        ? opportunity.fundingLabel(preferFundingNote: true)
        : OpportunityMetadata.buildCompensationLabel(
            salaryMin: opportunity.salaryMin,
            salaryMax: opportunity.salaryMax,
            salaryCurrency: opportunity.salaryCurrency,
            salaryPeriod: opportunity.salaryPeriod,
            compensationText: opportunity.compensationText,
            isPaid: opportunity.isPaid,
            preferCompensationText: true,
          );
    final applicationsCount = _asInt(
      preview.data['activityApplicationCount'],
      fallback: 0,
    );
    final requirements =
        (opportunity.requirementItems.isNotEmpty
                ? opportunity.requirementItems
                : <String>[opportunity.requirements])
            .map(DisplayText.capitalizeLeadingLabel)
            .where((item) => item.trim().isNotEmpty)
            .toList(growable: false);
    final benefits = opportunity.benefits
        .map(DisplayText.capitalizeLeadingLabel)
        .where((item) => item.trim().isNotEmpty)
        .toList(growable: false);
    final tags = opportunity.tags
        .map(DisplayText.capitalizeWords)
        .where((item) => item.trim().isNotEmpty)
        .toList(growable: false);

    return [
      _buildDetailHeroCard(
        title: opportunity.title.trim().isNotEmpty
            ? opportunity.title
            : 'Opportunity',
        subtitle: opportunity.companyName.trim().isNotEmpty
            ? opportunity.companyName
            : 'Unknown company',
        icon: Icons.work_outline_rounded,
        accentColor: typeColor,
        chips: [
          _buildHeroChip(typeLabel, Icons.work_history_outlined),
          if (statusLabel.isNotEmpty)
            _buildHeroChip(statusLabel, _ideaStatusIcon(opportunity.status)),
          if (workModeLabel.isNotEmpty)
            _buildHeroChip(workModeLabel, Icons.lan_outlined),
          if (opportunity.isFeatured)
            _buildHeroChip('Featured', Icons.workspace_premium_outlined),
        ],
      ),
      const SizedBox(height: 14),
      _buildDetailHighlightsGrid([
        _PreviewHighlightItem(
          icon: Icons.assignment_outlined,
          label: 'Applications',
          value: '$applicationsCount',
          color: AdminPalette.activity,
        ),
        if (opportunity.deadlineLabel.trim().isNotEmpty)
          _PreviewHighlightItem(
            icon: Icons.event_outlined,
            label: 'Deadline',
            value: opportunity.deadlineLabel,
            color: AdminPalette.primary,
          ),
        if ((compensationLabel ?? '').trim().isNotEmpty)
          _PreviewHighlightItem(
            icon: Icons.payments_outlined,
            label: 'Compensation',
            value: compensationLabel!,
            color: AdminPalette.success,
          ),
        _PreviewHighlightItem(
          icon: Icons.badge_outlined,
          label: 'Work Setup',
          value: workModeLabel.isNotEmpty
              ? workModeLabel
              : employmentLabel.isNotEmpty
              ? employmentLabel
              : typeLabel,
          color: typeColor,
        ),
      ]),
      if (description.trim().isNotEmpty) ...[
        const SizedBox(height: 14),
        _buildIdeaNarrativeCard(
          title: 'Role Overview',
          value: description,
          icon: Icons.description_outlined,
          color: typeColor,
        ),
      ],
      const SizedBox(height: 14),
      const AdminSectionHeader(
        eyebrow: 'Role Setup',
        title: 'Location And Logistics',
        subtitle:
            'These details help you evaluate how the opportunity is positioned for applicants.',
      ),
      const SizedBox(height: 12),
      _buildMetadataGrid([
        _PreviewDetailItem(
          'Company',
          opportunity.companyName,
          icon: Icons.business_outlined,
          color: typeColor,
        ),
        _PreviewDetailItem(
          'Location',
          opportunity.location,
          icon: Icons.location_on_outlined,
          color: AdminPalette.info,
        ),
        _PreviewDetailItem(
          'Type',
          typeLabel,
          icon: Icons.work_outline_rounded,
          color: typeColor,
        ),
        _PreviewDetailItem(
          'Status',
          statusLabel,
          icon: _ideaStatusIcon(opportunity.status),
          color: _statusColor(opportunity.status),
        ),
        _PreviewDetailItem(
          'Employment',
          employmentLabel,
          icon: Icons.badge_outlined,
          color: AdminPalette.primary,
        ),
        _PreviewDetailItem(
          'Work Mode',
          workModeLabel,
          icon: Icons.lan_outlined,
          color: AdminPalette.secondary,
        ),
        _PreviewDetailItem(
          'Paid Status',
          paidLabel,
          icon: Icons.account_balance_wallet_outlined,
          color: AdminPalette.success,
        ),
        _PreviewDetailItem(
          'Duration',
          opportunity.duration ?? '',
          icon: Icons.schedule_outlined,
          color: AdminPalette.textMuted,
        ),
        _PreviewDetailItem(
          'Deadline',
          opportunity.deadlineLabel,
          icon: Icons.event_outlined,
          color: AdminPalette.primary,
        ),
        _PreviewDetailItem(
          'Compensation',
          compensationLabel ?? '',
          icon: Icons.payments_outlined,
          color: AdminPalette.success,
        ),
      ]),
      if (requirements.isNotEmpty) ...[
        const SizedBox(height: 14),
        _buildDetailListCard(
          title: 'Requirements',
          subtitle:
              'These are the main qualifications or expectations shown to applicants.',
          items: requirements,
          icon: Icons.checklist_rounded,
          color: typeColor,
        ),
      ],
      if (benefits.isNotEmpty) ...[
        const SizedBox(height: 14),
        _buildDetailListCard(
          title: 'Benefits',
          subtitle:
              'This gives the admin view of what makes the role attractive.',
          items: benefits,
          icon: Icons.star_outline_rounded,
          color: AdminPalette.success,
        ),
      ],
      if (tags.isNotEmpty) ...[
        const SizedBox(height: 14),
        AdminSurface(
          radius: 20,
          padding: _largePanelPadding(context),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Tags',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: AdminPalette.textPrimary,
                ),
              ),
              const SizedBox(height: 12),
              _buildTagSection('Opportunity Tags', tags, typeColor),
            ],
          ),
        ),
      ],
    ];
  }

  List<Widget> _buildScholarshipSections(AdminActivityPreviewModel preview) {
    final scholarship = preview.data;
    final title = (scholarship['title'] ?? 'Scholarship').toString();
    final providerName = (scholarship['provider'] ?? 'Unknown provider')
        .toString();
    final description = DisplayText.capitalizeLeadingLabel(
      (scholarship['description'] ?? '').toString(),
    );
    final eligibility = DisplayText.capitalizeLeadingLabel(
      (scholarship['eligibility'] ?? '').toString(),
    );
    final amountText = scholarship['amount'] == null
        ? ''
        : '${scholarship['amount']} DA';
    final deadlineText = (scholarship['deadline'] ?? '').toString().trim();
    final categoryText =
        (scholarship['category'] ??
                scholarship['domain'] ??
                scholarship['field'] ??
                '')
            .toString();
    final levelText =
        (scholarship['level'] ??
                scholarship['academicLevel'] ??
                scholarship['studyLevel'] ??
                '')
            .toString();
    final locationText =
        (scholarship['location'] ??
                scholarship['country'] ??
                scholarship['destination'] ??
                '')
            .toString();
    final link = (scholarship['link'] ?? '').toString().trim();
    final tags = OpportunityMetadata.stringListFromValue(
      scholarship['tags'] ??
          scholarship['domains'] ??
          scholarship['categories'] ??
          scholarship['fields'],
      maxItems: 6,
    ).map(DisplayText.capitalizeWords).toList(growable: false);

    return [
      _buildDetailHeroCard(
        title: title,
        subtitle: providerName,
        icon: Icons.card_giftcard_rounded,
        accentColor: Colors.pink,
        chips: [
          if (amountText.isNotEmpty)
            _buildHeroChip('Funding', Icons.savings_outlined),
          if (deadlineText.isNotEmpty)
            _buildHeroChip('Deadline Set', Icons.event_outlined),
          if (link.isNotEmpty)
            _buildHeroChip('External Link', Icons.open_in_new_rounded),
        ],
      ),
      const SizedBox(height: 14),
      _buildDetailHighlightsGrid([
        if (amountText.isNotEmpty)
          _PreviewHighlightItem(
            icon: Icons.payments_outlined,
            label: 'Amount',
            value: amountText,
            color: AdminPalette.success,
          ),
        if (deadlineText.isNotEmpty)
          _PreviewHighlightItem(
            icon: Icons.event_outlined,
            label: 'Deadline',
            value: deadlineText,
            color: Colors.pink,
          ),
        _PreviewHighlightItem(
          icon: Icons.business_outlined,
          label: 'Provider',
          value: providerName,
          color: Colors.pink,
        ),
        _PreviewHighlightItem(
          icon: link.isNotEmpty ? Icons.link_rounded : Icons.link_off_rounded,
          label: 'Access',
          value: link.isNotEmpty ? 'Application Link Ready' : 'Link not added',
          color: link.isNotEmpty ? AdminPalette.info : AdminPalette.textMuted,
        ),
      ]),
      if (description.trim().isNotEmpty) ...[
        const SizedBox(height: 14),
        _buildIdeaNarrativeCard(
          title: 'Scholarship Overview',
          value: description,
          icon: Icons.description_outlined,
          color: Colors.pink,
        ),
      ],
      if (eligibility.trim().isNotEmpty) ...[
        const SizedBox(height: 14),
        _buildIdeaNarrativeCard(
          title: 'Eligibility',
          value: eligibility,
          icon: Icons.verified_user_outlined,
          color: Colors.orange,
        ),
      ],
      const SizedBox(height: 14),
      const AdminSectionHeader(
        eyebrow: 'Scholarship Details',
        title: 'Provider And Access',
        subtitle:
            'These details help you review where the scholarship fits and how students will reach it.',
      ),
      const SizedBox(height: 12),
      _buildMetadataGrid([
        _PreviewDetailItem(
          'Provider',
          providerName,
          icon: Icons.business_outlined,
          color: Colors.pink,
        ),
        _PreviewDetailItem(
          'Amount',
          amountText,
          icon: Icons.payments_outlined,
          color: AdminPalette.success,
        ),
        _PreviewDetailItem(
          'Deadline',
          deadlineText,
          icon: Icons.event_outlined,
          color: Colors.pink,
        ),
        _PreviewDetailItem(
          'Category',
          DisplayText.capitalizeWords(categoryText),
          icon: Icons.category_outlined,
          color: AdminPalette.info,
        ),
        _PreviewDetailItem(
          'Level',
          DisplayText.capitalizeWords(levelText),
          icon: Icons.school_outlined,
          color: AdminPalette.primary,
        ),
        _PreviewDetailItem(
          'Location',
          DisplayText.capitalizeLeadingLabel(locationText),
          icon: Icons.public_rounded,
          color: AdminPalette.secondary,
        ),
        _PreviewDetailItem(
          'Access',
          link.isNotEmpty ? 'External Link Available' : 'Link unavailable',
          icon: link.isNotEmpty
              ? Icons.open_in_new_rounded
              : Icons.link_off_rounded,
          color: link.isNotEmpty ? AdminPalette.info : AdminPalette.textMuted,
        ),
      ]),
      if (tags.isNotEmpty) ...[
        const SizedBox(height: 14),
        AdminSurface(
          radius: 20,
          padding: _largePanelPadding(context),
          child: _buildTagSection('Scholarship Tags', tags, Colors.pink),
        ),
      ],
    ];
  }

  List<Widget> _buildTrainingSections(AdminActivityPreviewModel preview) {
    final training = TrainingModel.fromMap(preview.data);
    final description = DisplayText.capitalizeLeadingLabel(
      training.description,
    );
    final trainingAccentColor = _trainingAccentColor(training.type);
    final providerName = training.provider.isNotEmpty
        ? training.provider
        : 'Training';
    final typeLabel = DisplayText.capitalizeWords(training.type);
    final domainLabel = DisplayText.capitalizeWords(training.domain);
    final levelLabel = DisplayText.capitalizeWords(training.level);
    final sourceLabel = DisplayText.capitalizeWords(training.source);
    final accessLabel = training.isFree == null
        ? ''
        : training.isFree!
        ? 'Free'
        : 'Paid';
    final certificateLabel = training.hasCertificate == null
        ? ''
        : training.hasCertificate!
        ? 'Certificate Available'
        : 'Certificate not included';
    final learnerLabel = training.learnerCountLabel.trim().isNotEmpty
        ? training.learnerCountLabel.trim()
        : training.learnerCount?.toString() ?? '';
    final ratingLabel = training.rating == null
        ? ''
        : training.rating!.toStringAsFixed(1);
    final authors = training.authors
        .map(DisplayText.capitalizeLeadingLabel)
        .where((item) => item.trim().isNotEmpty)
        .toList(growable: false);

    return [
      _buildDetailHeroCard(
        title: training.title.trim().isNotEmpty ? training.title : 'Training',
        subtitle: providerName,
        icon: _trainingIcon(training.type),
        accentColor: trainingAccentColor,
        chips: [
          _buildHeroChip(typeLabel, _trainingIcon(training.type)),
          if (domainLabel.isNotEmpty)
            _buildHeroChip(domainLabel, Icons.category_outlined),
          if (levelLabel.isNotEmpty)
            _buildHeroChip(levelLabel, Icons.timeline_outlined),
          if (training.isFeatured)
            _buildHeroChip('Featured', Icons.workspace_premium_outlined),
        ],
      ),
      const SizedBox(height: 14),
      _buildDetailHighlightsGrid([
        if (training.duration.trim().isNotEmpty)
          _PreviewHighlightItem(
            icon: Icons.schedule_outlined,
            label: 'Duration',
            value: training.duration,
            color: trainingAccentColor,
          ),
        if (learnerLabel.isNotEmpty)
          _PreviewHighlightItem(
            icon: Icons.groups_rounded,
            label: 'Learners',
            value: learnerLabel,
            color: AdminPalette.info,
          ),
        if (ratingLabel.isNotEmpty)
          _PreviewHighlightItem(
            icon: Icons.star_outline_rounded,
            label: 'Rating',
            value: ratingLabel,
            color: AdminPalette.primary,
          ),
        _PreviewHighlightItem(
          icon: training.isApproved
              ? Icons.check_circle_outline_rounded
              : Icons.hourglass_top_rounded,
          label: 'Status',
          value: training.isApproved ? 'Approved' : 'Pending Review',
          color: training.isApproved
              ? AdminPalette.success
              : AdminPalette.warning,
        ),
      ]),
      if (description.trim().isNotEmpty) ...[
        const SizedBox(height: 14),
        _buildIdeaNarrativeCard(
          title: 'Training Overview',
          value: description,
          icon: Icons.description_outlined,
          color: trainingAccentColor,
        ),
      ],
      const SizedBox(height: 14),
      const AdminSectionHeader(
        eyebrow: 'Resource Details',
        title: 'Provider And Delivery Setup',
        subtitle:
            'This section helps you review how the training is packaged and presented to users.',
      ),
      const SizedBox(height: 12),
      _buildMetadataGrid([
        _PreviewDetailItem(
          'Provider',
          providerName,
          icon: Icons.business_outlined,
          color: trainingAccentColor,
        ),
        _PreviewDetailItem(
          'Type',
          typeLabel,
          icon: _trainingIcon(training.type),
          color: trainingAccentColor,
        ),
        _PreviewDetailItem(
          'Source',
          sourceLabel,
          icon: Icons.cloud_outlined,
          color: AdminPalette.secondary,
        ),
        _PreviewDetailItem(
          'Domain',
          domainLabel,
          icon: Icons.category_outlined,
          color: AdminPalette.info,
        ),
        _PreviewDetailItem(
          'Level',
          levelLabel,
          icon: Icons.timeline_outlined,
          color: AdminPalette.primary,
        ),
        _PreviewDetailItem(
          'Language',
          DisplayText.capitalizeWords(training.language),
          icon: Icons.translate_rounded,
          color: AdminPalette.activity,
        ),
        _PreviewDetailItem(
          'Access',
          accessLabel,
          icon: Icons.payments_outlined,
          color: training.isFree == true
              ? AdminPalette.success
              : AdminPalette.warning,
        ),
        _PreviewDetailItem(
          'Certificate',
          certificateLabel,
          icon: Icons.verified_outlined,
          color: AdminPalette.success,
        ),
      ]),
      if (authors.isNotEmpty) ...[
        const SizedBox(height: 14),
        AdminSurface(
          radius: 20,
          padding: _largePanelPadding(context),
          child: _buildTagSection('Authors', authors, trainingAccentColor),
        ),
      ],
    ];
  }

  List<Widget> _buildProjectIdeaSections(AdminActivityPreviewModel preview) {
    final idea = ProjectIdeaModel.fromMap(preview.data);
    final submitterLabel = idea.submittedByName.trim().isNotEmpty
        ? idea.submittedByName
        : idea.submittedBy;
    final title = _formatIdeaTitle(idea.title);
    final subtitle =
        'Submitted By ${DisplayText.capitalizeLeadingLabel(submitterLabel)}';
    final summary = _formatIdeaDescription(idea.featuredSummary);
    final tagline = _formatIdeaDescription(idea.tagline);
    final targetAudience = _formatIdeaDescription(idea.targetAudience);
    final problemText = _formatIdeaDescription(idea.problemText);
    final solutionText = _formatIdeaDescription(idea.solutionText);
    final benefitsText = _formatIdeaDescription(idea.impactText);
    final statusColor = _statusColor(idea.status);
    final skills = idea.displaySkills
        .map(_formatIdeaBadgeValue)
        .where((value) => value.trim().isNotEmpty)
        .toList(growable: false);
    final teamNeeded = idea.displayTeamNeeded
        .map(_formatIdeaBadgeValue)
        .where((value) => value.trim().isNotEmpty)
        .toList(growable: false);
    final tags = idea.tags
        .map(_formatIdeaBadgeValue)
        .where((value) => value.trim().isNotEmpty)
        .toList(growable: false);

    return [
      _buildDetailHeroCard(
        title: title.isNotEmpty ? title : 'Project Idea',
        subtitle: subtitle,
        icon: Icons.lightbulb_outline_rounded,
        accentColor: AdminPalette.warning,
        chips: [
          _buildHeroChip(
            _formatIdeaBadgeValue(idea.status),
            _ideaStatusIcon(idea.status),
          ),
          _buildHeroChip(
            _formatIdeaBadgeValue(idea.displayCategory),
            Icons.category_outlined,
          ),
          _buildHeroChip(
            _formatIdeaBadgeValue(idea.displayStage),
            Icons.timeline_outlined,
          ),
          _buildHeroChip(
            idea.isPublic ? 'Public' : 'Private',
            idea.isPublic ? Icons.public_rounded : Icons.lock_outline_rounded,
          ),
        ],
      ),
      const SizedBox(height: 14),
      _buildDetailHighlightsGrid([
        _PreviewHighlightItem(
          icon: _ideaStatusIcon(idea.status),
          label: 'Status',
          value: _formatIdeaBadgeValue(idea.status),
          color: statusColor,
        ),
        _PreviewHighlightItem(
          icon: Icons.bolt_rounded,
          label: 'Sparks',
          value: '${idea.sparksCount}',
          color: AdminPalette.warning,
        ),
        _PreviewHighlightItem(
          icon: Icons.groups_rounded,
          label: 'Interested',
          value: '${idea.interestedCount}',
          color: AdminPalette.info,
        ),
        _PreviewHighlightItem(
          icon: Icons.remove_red_eye_outlined,
          label: 'Views',
          value: '${idea.viewsCount}',
          color: AdminPalette.activity,
        ),
      ]),
      if (summary.trim().isNotEmpty) ...[
        const SizedBox(height: 14),
        AdminSurface(
          radius: 20,
          padding: _largePanelPadding(context),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Overview',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: AdminPalette.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                summary,
                style: const TextStyle(
                  fontSize: 13.2,
                  height: 1.6,
                  color: AdminPalette.textSecondary,
                ),
              ),
              if (tagline.trim().isNotEmpty) ...[
                const SizedBox(height: 12),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AdminPalette.warning.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Text(
                    tagline,
                    style: const TextStyle(
                      fontSize: 12.8,
                      fontWeight: FontWeight.w600,
                      height: 1.5,
                      color: AdminPalette.warning,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
      if (problemText.trim().isNotEmpty ||
          solutionText.trim().isNotEmpty ||
          benefitsText.trim().isNotEmpty) ...[
        const SizedBox(height: 14),
        const AdminSectionHeader(
          eyebrow: 'Build Story',
          title: 'Problem, Solution, And Impact',
          subtitle:
              'This section shows what the idea is solving, how it works, and the value it aims to create.',
        ),
        const SizedBox(height: 12),
        if (problemText.trim().isNotEmpty) ...[
          _buildIdeaNarrativeCard(
            title: 'Problem Statement',
            value: problemText,
            icon: Icons.report_problem_outlined,
            color: Colors.orange,
          ),
          const SizedBox(height: 10),
        ],
        if (solutionText.trim().isNotEmpty) ...[
          _buildIdeaNarrativeCard(
            title: 'Proposed Solution',
            value: solutionText,
            icon: Icons.auto_fix_high_outlined,
            color: AdminPalette.warning,
          ),
          const SizedBox(height: 10),
        ],
        if (benefitsText.trim().isNotEmpty)
          _buildIdeaNarrativeCard(
            title: 'Expected Benefits',
            value: benefitsText,
            icon: Icons.trending_up_rounded,
            color: AdminPalette.success,
          ),
      ],
      const SizedBox(height: 14),
      const AdminSectionHeader(
        eyebrow: 'Positioning',
        title: 'Audience And Metadata',
        subtitle:
            'These fields help you judge where the idea fits and how ready it is for review.',
      ),
      const SizedBox(height: 12),
      _buildMetadataGrid([
        _PreviewDetailItem(
          'Category',
          _formatIdeaBadgeValue(idea.displayCategory),
          icon: Icons.category_outlined,
          color: AdminPalette.info,
        ),
        _PreviewDetailItem(
          'Stage',
          _formatIdeaBadgeValue(idea.displayStage),
          icon: Icons.timeline_outlined,
          color: AdminPalette.activity,
        ),
        _PreviewDetailItem(
          'Level',
          _formatIdeaBadgeValue(idea.level),
          icon: Icons.school_outlined,
          color: AdminPalette.primary,
        ),
        _PreviewDetailItem(
          'Status',
          _formatIdeaBadgeValue(idea.status),
          icon: _ideaStatusIcon(idea.status),
          color: statusColor,
        ),
        _PreviewDetailItem(
          'Audience',
          targetAudience,
          icon: Icons.groups_2_outlined,
          color: AdminPalette.secondary,
        ),
        _PreviewDetailItem(
          'Visibility',
          idea.isPublic ? 'Public Idea' : 'Private Idea',
          icon: idea.isPublic
              ? Icons.public_rounded
              : Icons.lock_outline_rounded,
          color: idea.isPublic ? AdminPalette.success : AdminPalette.textMuted,
        ),
        _PreviewDetailItem(
          'Submitted',
          _formatTimestamp(idea.createdAt),
          icon: Icons.event_outlined,
          color: AdminPalette.textMuted,
        ),
        _PreviewDetailItem(
          'Last Updated',
          _buildIdeaUpdatedLabel(idea),
          icon: Icons.update_rounded,
          color: AdminPalette.warning,
        ),
      ]),
      if (skills.isNotEmpty || teamNeeded.isNotEmpty || tags.isNotEmpty) ...[
        const SizedBox(height: 14),
        AdminSurface(
          radius: 20,
          padding: _largePanelPadding(context),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const AdminSectionHeader(
                eyebrow: 'Collaboration',
                title: 'Team And Skill Signals',
                subtitle:
                    'Use these tags to understand what support the idea needs next.',
              ),
              if (skills.isNotEmpty) ...[
                const SizedBox(height: 12),
                _buildTagSection('Skills Needed', skills, AdminPalette.warning),
              ],
              if (teamNeeded.isNotEmpty) ...[
                const SizedBox(height: 12),
                _buildTagSection('Team Needed', teamNeeded, AdminPalette.info),
              ],
              if (tags.isNotEmpty) ...[
                const SizedBox(height: 12),
                _buildTagSection('Tags', tags, AdminPalette.activity),
              ],
            ],
          ),
        ),
      ],
    ];
  }

  Widget _buildHeroChip(String label, IconData icon) {
    return AdminActionChip(label: label, icon: icon, color: Colors.white);
  }

  List<Widget> _buildDetailLineWidgets(List<_PreviewDetailLine> lines) {
    final visibleLines = lines
        .where((line) => line.value.trim().isNotEmpty)
        .toList(growable: false);
    return visibleLines
        .map(
          (line) => Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: _buildDetailLine(line.label, line.value),
          ),
        )
        .toList(growable: false);
  }

  Widget _buildDetailHeroCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color accentColor,
    List<Widget> chips = const [],
  }) {
    return AdminSurface(
      padding: _heroPanelPadding(context),
      radius: 24,
      gradient: AdminPalette.heroGradient(accentColor),
      border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
      child: SizedBox(
        width: double.infinity,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: Colors.white, size: 30),
            const SizedBox(height: 12),
            Text(
              title,
              style: const TextStyle(
                fontSize: 21,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
            if (subtitle.trim().isNotEmpty) ...[
              const SizedBox(height: 6),
              Text(
                subtitle,
                style: const TextStyle(
                  fontSize: 13,
                  color: Colors.white70,
                  height: 1.45,
                ),
              ),
            ],
            if (chips.isNotEmpty) ...[
              const SizedBox(height: 12),
              Wrap(spacing: 8, runSpacing: 8, children: chips),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildDetailHighlightsGrid(List<_PreviewHighlightItem> items) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final crossAxisCount = constraints.maxWidth < 320 ? 1 : 2;

        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: items.length,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            mainAxisSpacing: 10,
            crossAxisSpacing: 10,
            mainAxisExtent: 112,
          ),
          itemBuilder: (context, index) => _buildHighlightCard(items[index]),
        );
      },
    );
  }

  Widget _buildHighlightCard(_PreviewHighlightItem item) {
    return AdminSurface(
      radius: 18,
      color: AdminPalette.surfaceMuted,
      boxShadow: const [],
      border: Border.all(color: item.color.withValues(alpha: 0.14)),
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: item.color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(item.icon, color: item.color, size: 17),
          ),
          const SizedBox(height: 10),
          Text(
            item.label,
            style: const TextStyle(
              fontSize: 11.5,
              fontWeight: FontWeight.w700,
              color: AdminPalette.textMuted,
            ),
          ),
          const SizedBox(height: 4),
          Expanded(
            child: Align(
              alignment: Alignment.bottomLeft,
              child: Text(
                item.value,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 14.5,
                  fontWeight: FontWeight.w700,
                  color: AdminPalette.textPrimary,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildIdeaNarrativeCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return AdminSurface(
      padding: _largePanelPadding(context),
      radius: 20,
      child: SizedBox(
        width: double.infinity,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, color: color, size: 18),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: AdminPalette.textPrimary,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              value,
              style: const TextStyle(
                fontSize: 13.2,
                height: 1.6,
                color: AdminPalette.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailListCard({
    required String title,
    required List<String> items,
    required IconData icon,
    required Color color,
    String? subtitle,
  }) {
    final visibleItems = items
        .map((item) => item.trim())
        .where((item) => item.isNotEmpty)
        .toList(growable: false);
    if (visibleItems.isEmpty) {
      return const SizedBox.shrink();
    }

    return AdminSurface(
      padding: _largePanelPadding(context),
      radius: 20,
      child: SizedBox(
        width: double.infinity,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, color: color, size: 18),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: AdminPalette.textPrimary,
                        ),
                      ),
                      if ((subtitle ?? '').trim().isNotEmpty) ...[
                        const SizedBox(height: 2),
                        Text(
                          subtitle!,
                          style: const TextStyle(
                            fontSize: 12,
                            color: AdminPalette.textMuted,
                            height: 1.45,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ...visibleItems.asMap().entries.map((entry) {
              final isLast = entry.key == visibleItems.length - 1;
              return Padding(
                padding: EdgeInsets.only(bottom: isLast ? 0 : 10),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 7,
                      height: 7,
                      margin: const EdgeInsets.only(top: 6),
                      decoration: BoxDecoration(
                        color: color,
                        borderRadius: BorderRadius.circular(999),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        entry.value,
                        style: const TextStyle(
                          fontSize: 13.2,
                          height: 1.55,
                          color: AdminPalette.textSecondary,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildMetadataGrid(List<_PreviewDetailItem> items) {
    final visibleItems = items
        .where((item) => item.value.trim().isNotEmpty)
        .toList(growable: false);

    return LayoutBuilder(
      builder: (context, constraints) {
        final crossAxisCount = constraints.maxWidth < 320 ? 1 : 2;
        final mainAxisExtent = crossAxisCount == 1 ? 104.0 : 120.0;

        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: visibleItems.length,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            mainAxisSpacing: 10,
            crossAxisSpacing: 10,
            mainAxisExtent: mainAxisExtent,
          ),
          itemBuilder: (context, index) =>
              _buildMetadataCard(visibleItems[index]),
        );
      },
    );
  }

  Widget _buildMetadataCard(_PreviewDetailItem item) {
    return AdminSurface(
      radius: 18,
      color: AdminPalette.surfaceMuted,
      boxShadow: const [],
      border: Border.all(color: item.color.withValues(alpha: 0.12)),
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: item.color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(9),
                ),
                child: Icon(item.icon, color: item.color, size: 16),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  item.label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w700,
                    color: AdminPalette.textMuted,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Expanded(
            child: Align(
              alignment: Alignment.topLeft,
              child: Text(
                item.value,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 13.4,
                  height: 1.45,
                  color: AdminPalette.textPrimary,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTagSection(String title, List<String> items, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            color: AdminPalette.textPrimary,
          ),
        ),
        const SizedBox(height: 6),
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: items
              .map(
                (item) => Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    item,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: color,
                    ),
                  ),
                ),
              )
              .toList(growable: false),
        ),
      ],
    );
  }

  Widget _buildDetailLine(String label, String value) {
    return AdminSurface(
      padding: _detailLinePadding(context),
      radius: 18,
      child: SizedBox(
        width: double.infinity,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: const TextStyle(
                fontSize: 11.5,
                fontWeight: FontWeight.w700,
                color: AdminPalette.textMuted,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              value.trim().isEmpty ? 'Not available' : value,
              style: const TextStyle(
                fontSize: 13.5,
                height: 1.45,
                color: AdminPalette.textPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  static double _sheetHorizontalPadding(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    if (width < 360) {
      return 12;
    }
    if (width < 420) {
      return 16;
    }
    return 20;
  }

  static EdgeInsets _heroPanelPadding(BuildContext context) {
    final compact = MediaQuery.sizeOf(context).width < 380;
    return EdgeInsets.all(compact ? 14 : 16);
  }

  static EdgeInsets _largePanelPadding(BuildContext context) {
    final compact = MediaQuery.sizeOf(context).width < 380;
    return EdgeInsets.all(compact ? 14 : 16);
  }

  static EdgeInsets _detailLinePadding(BuildContext context) {
    final compact = MediaQuery.sizeOf(context).width < 380;
    return EdgeInsets.fromLTRB(compact ? 14 : 16, 12, compact ? 14 : 16, 12);
  }

  static int _asInt(dynamic value, {int fallback = 0}) {
    if (value is int) {
      return value;
    }
    if (value is num) {
      return value.toInt();
    }
    return int.tryParse(value?.toString().trim() ?? '') ?? fallback;
  }

  static String _formatIdeaTitle(String text) {
    return DisplayText.capitalizeWords(text);
  }

  static String _formatIdeaDescription(String text) {
    return DisplayText.capitalizeLeadingLabel(text);
  }

  static String _formatIdeaBadgeValue(String text) {
    return DisplayText.capitalizeWords(text);
  }

  static String _buildIdeaUpdatedLabel(ProjectIdeaModel idea) {
    final timestamp = idea.updatedAt ?? idea.createdAt;
    if (timestamp == null) {
      return 'Updated recently';
    }

    final date = timestamp.toDate();
    final difference = DateTime.now().difference(date);
    if (difference.inMinutes < 60) {
      final minutes = difference.inMinutes <= 1 ? 1 : difference.inMinutes;
      return 'Updated $minutes min ago';
    }
    if (difference.inHours < 24) {
      final hours = difference.inHours <= 1 ? 1 : difference.inHours;
      return 'Updated $hours hr ago';
    }
    if (difference.inDays < 7) {
      final days = difference.inDays <= 1 ? 1 : difference.inDays;
      return 'Updated $days day${days == 1 ? '' : 's'} ago';
    }

    return 'Updated ${DateFormat('MMM d, yyyy').format(date)}';
  }

  static IconData _ideaStatusIcon(String status) {
    switch (status.trim().toLowerCase()) {
      case 'approved':
      case 'accepted':
        return Icons.check_circle_outline_rounded;
      case 'rejected':
        return Icons.cancel_outlined;
      case 'open':
        return Icons.lock_open_rounded;
      case 'featured':
        return Icons.workspace_premium_outlined;
      default:
        return Icons.hourglass_top_rounded;
    }
  }

  static Color _statusColor(String status) {
    switch (status.trim().toLowerCase()) {
      case 'approved':
      case 'accepted':
      case 'open':
        return Colors.green;
      case 'rejected':
        return Colors.red;
      case 'featured':
        return AdminPalette.primary;
      default:
        return Colors.orange;
    }
  }

  static IconData _trainingIcon(String type) {
    switch (type.trim().toLowerCase()) {
      case 'book':
        return Icons.menu_book_rounded;
      case 'video':
        return Icons.ondemand_video_outlined;
      case 'file':
        return Icons.description_outlined;
      case 'course':
        return Icons.school_outlined;
      default:
        return Icons.cast_for_education_outlined;
    }
  }

  static Color _trainingAccentColor(String type) {
    switch (type.trim().toLowerCase()) {
      case 'book':
        return const Color(0xFF0F766E);
      case 'video':
        return const Color(0xFFDC2626);
      case 'file':
        return const Color(0xFF475569);
      case 'course':
        return const Color(0xFF0284C7);
      default:
        return Colors.cyan;
    }
  }

  static IconData _activityIcon(String type) {
    switch (type) {
      case 'application':
        return Icons.assignment_outlined;
      case 'opportunity':
        return Icons.work_outline_rounded;
      case 'scholarship':
        return Icons.card_giftcard_rounded;
      case 'training':
        return Icons.cast_for_education_outlined;
      default:
        return Icons.lightbulb_outline_rounded;
    }
  }

  static Color _accentColor(String type) {
    switch (type) {
      case 'application':
        return AdminPalette.activity;
      case 'opportunity':
        return AdminPalette.accent;
      case 'scholarship':
        return Colors.pink;
      case 'training':
        return AdminPalette.secondary;
      default:
        return AdminPalette.warning;
    }
  }

  static String _formatShortDate(Timestamp? timestamp) {
    if (timestamp == null) {
      return 'Date unknown';
    }
    return DateFormat('MMM d, yyyy').format(timestamp.toDate());
  }

  static String _formatTimestamp(Timestamp? timestamp) {
    if (timestamp == null) {
      return 'Unknown time';
    }
    return DateFormat('MMM d, yyyy - HH:mm').format(timestamp.toDate());
  }
}

class _LoadingCard extends StatelessWidget {
  const _LoadingCard();

  @override
  Widget build(BuildContext context) {
    return const AdminSurface(
      radius: 24,
      child: SizedBox(
        height: 220,
        child: Center(
          child: CircularProgressIndicator(color: AdminPalette.primary),
        ),
      ),
    );
  }
}

class _UnavailableCard extends StatelessWidget {
  final AdminActivityModel activity;

  const _UnavailableCard({required this.activity});

  @override
  Widget build(BuildContext context) {
    final accentColor = _AdminActivityPreviewSheetState._accentColor(
      activity.type,
    );

    return AdminSurface(
      radius: 24,
      child: Column(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: accentColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(18),
            ),
            child: Icon(
              _AdminActivityPreviewSheetState._activityIcon(activity.type),
              color: accentColor,
              size: 24,
            ),
          ),
          const SizedBox(height: 14),
          const Text(
            'Details unavailable',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: AdminPalette.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'We couldn\'t load the linked ${activity.type.replaceAll('_', ' ')} record right now.',
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 13,
              height: 1.5,
              color: AdminPalette.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

class _PreviewHighlightItem {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _PreviewHighlightItem({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });
}

class _PreviewDetailItem {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const _PreviewDetailItem(
    this.label,
    this.value, {
    required this.icon,
    required this.color,
  });
}

class _PreviewDetailLine {
  final String label;
  final String value;

  const _PreviewDetailLine(this.label, this.value);
}
