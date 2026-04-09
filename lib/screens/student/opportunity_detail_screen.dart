import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../models/opportunity_model.dart';
import '../../models/saved_opportunity_model.dart';
import '../../providers/application_provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/cv_provider.dart';
import '../../providers/saved_opportunity_provider.dart';
import '../../services/application_service.dart';
import '../../utils/application_status.dart';
import '../../utils/opportunity_metadata.dart';
import '../../utils/opportunity_type.dart';
import '../../widgets/app_shell_background.dart';
import '../../widgets/shared/app_content_system.dart';
import '../../widgets/shared/app_feedback.dart';

class OpportunityDetailScreen extends StatelessWidget {
  final OpportunityModel opportunity;

  const OpportunityDetailScreen({super.key, required this.opportunity});

  static Future<void> show(BuildContext context, OpportunityModel opportunity) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (_) =>
          OpportunityDetailsScreen(opportunity: opportunity, isSheet: true),
    );
  }

  @override
  Widget build(BuildContext context) {
    return OpportunityDetailsScreen(opportunity: opportunity);
  }
}

class OpportunityDetailsScreen extends StatefulWidget {
  final OpportunityModel opportunity;
  final String? type;
  final bool isSheet;

  const OpportunityDetailsScreen({
    super.key,
    required this.opportunity,
    this.type,
    this.isSheet = false,
  });

  @override
  State<OpportunityDetailsScreen> createState() =>
      _OpportunityDetailsScreenState();
}

class _OpportunityDetailsScreenState extends State<OpportunityDetailsScreen> {
  late Future<ApplicationEligibilityStatus> _eligibilityFuture;
  bool _isBookmarkBusy = false;

  String get _effectiveType =>
      OpportunityType.parse(widget.type ?? widget.opportunity.type);

  AppContentTheme get _theme {
    switch (_effectiveType) {
      case OpportunityType.internship:
        return const AppContentTheme(
          accent: Color(0xFF14B8A6),
          accentDark: Color(0xFF4338CA),
          accentSoft: Color(0xFFDDF8F6),
          secondary: Color(0xFF4F46E5),
          background: Color(0xFFF3FBFC),
          surface: Colors.white,
          surfaceMuted: Color(0xFFF5FFFE),
          border: Color(0xFFE2E8F0),
          textPrimary: Color(0xFF0F172A),
          textSecondary: Color(0xFF475569),
          textMuted: Color(0xFF64748B),
          success: Color(0xFF22C55E),
          warning: Color(0xFFF59E0B),
          error: Color(0xFFEF4444),
          heroGradient: LinearGradient(
            colors: <Color>[Color(0xFF14B8A6), Color(0xFF4F46E5)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        );
      case OpportunityType.sponsoring:
        return const AppContentTheme(
          accent: Color(0xFFF97316),
          accentDark: Color(0xFF1E40AF),
          accentSoft: Color(0xFFFFEDD5),
          secondary: Color(0xFF1E40AF),
          background: Color(0xFFFFFBF5),
          surface: Colors.white,
          surfaceMuted: Color(0xFFFFF7ED),
          border: Color(0xFFF1E2CC),
          textPrimary: Color(0xFF111827),
          textSecondary: Color(0xFF4B5563),
          textMuted: Color(0xFF6B7280),
          success: Color(0xFF22C55E),
          warning: Color(0xFFF59E0B),
          error: Color(0xFFEF4444),
          heroGradient: LinearGradient(
            colors: <Color>[Color(0xFF1E40AF), Color(0xFFF97316)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        );
      case OpportunityType.job:
      default:
        return const AppContentTheme(
          accent: Color(0xFF3B22F6),
          accentDark: Color(0xFF1E40AF),
          accentSoft: Color(0xFFE8E9FF),
          secondary: Color(0xFF14B8A6),
          background: Color(0xFFF5F7FF),
          surface: Colors.white,
          surfaceMuted: Color(0xFFF7F8FF),
          border: Color(0xFFE2E8F0),
          textPrimary: Color(0xFF111827),
          textSecondary: Color(0xFF475569),
          textMuted: Color(0xFF64748B),
          success: Color(0xFF22C55E),
          warning: Color(0xFFF59E0B),
          error: Color(0xFFEF4444),
          heroGradient: LinearGradient(
            colors: <Color>[Color(0xFF3B22F6), Color(0xFF1E40AF)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        );
    }
  }

  @override
  void initState() {
    super.initState();
    _eligibilityFuture = _loadEligibility();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }
      _ensureSavedStateLoaded();
      _ensureApplicationsLoaded();
    });
  }

  Future<ApplicationEligibilityStatus> _loadEligibility() {
    final currentUser = context.read<AuthProvider>().userModel;
    return context.read<ApplicationProvider>().getEligibility(
      studentId: currentUser?.uid ?? '',
      opportunityId: widget.opportunity.id,
    );
  }

  Future<void> _ensureSavedStateLoaded() async {
    final currentUser = context.read<AuthProvider>().userModel;
    final savedProvider = context.read<SavedOpportunityProvider>();

    if (currentUser == null ||
        currentUser.uid.isEmpty ||
        savedProvider.isLoading ||
        savedProvider.savedOpportunities.isNotEmpty) {
      return;
    }

    await savedProvider.fetchSavedOpportunities(currentUser.uid);
  }

  Future<void> _ensureApplicationsLoaded() async {
    final currentUser = context.read<AuthProvider>().userModel;
    final applicationProvider = context.read<ApplicationProvider>();

    if (currentUser == null ||
        currentUser.uid.isEmpty ||
        applicationProvider.submittedApplicationsLoading ||
        applicationProvider.submittedApplications.isNotEmpty) {
      return;
    }

    await applicationProvider.fetchSubmittedApplications(currentUser.uid);
  }

  void _refreshEligibility() {
    setState(() {
      _eligibilityFuture = _loadEligibility();
    });
  }

  Future<void> _apply() async {
    final authProvider = context.read<AuthProvider>();
    final applicationProvider = context.read<ApplicationProvider>();
    final cvProvider = context.read<CvProvider>();
    final currentUser = authProvider.userModel;

    if (currentUser == null) {
      context.showAppSnackBar(
        'Sign in to continue with your application.',
        title: 'Login required',
        type: AppFeedbackType.warning,
      );
      return;
    }

    final eligibility = await applicationProvider.getEligibility(
      studentId: currentUser.uid,
      opportunityId: widget.opportunity.id,
    );

    if (!mounted) {
      return;
    }

    if (eligibility != ApplicationEligibilityStatus.available) {
      context.showAppSnackBar(
        _messageForStatus(eligibility),
        title: 'Application blocked',
        type: AppFeedbackType.warning,
      );
      _refreshEligibility();
      return;
    }

    await cvProvider.loadCv(currentUser.uid);
    if (!mounted) {
      return;
    }

    final cv = cvProvider.cv;
    if (cv == null) {
      context.showAppSnackBar(
        'Create your CV before applying to this opportunity.',
        title: 'CV required',
        type: AppFeedbackType.warning,
      );
      return;
    }

    final error = await applicationProvider.applyToOpportunity(
      studentId: currentUser.uid,
      studentName: currentUser.fullName,
      opportunityId: widget.opportunity.id,
      cvId: cv.id,
    );

    if (!mounted) {
      return;
    }

    context.showAppSnackBar(
      error ?? 'Your application has been submitted successfully.',
      title: error == null ? 'Application sent' : 'Application unavailable',
      type: error == null ? AppFeedbackType.success : AppFeedbackType.error,
    );
    _refreshEligibility();
  }

  Future<void> _toggleSavedOpportunity() async {
    final authProvider = context.read<AuthProvider>();
    final savedProvider = context.read<SavedOpportunityProvider>();
    final currentUser = authProvider.userModel;

    if (_isBookmarkBusy) {
      return;
    }
    if (currentUser == null) {
      context.showAppSnackBar(
        'Sign in to save opportunities for later.',
        title: 'Login required',
        type: AppFeedbackType.warning,
      );
      return;
    }

    final existingSaved = _existingSavedOpportunity(savedProvider);
    setState(() => _isBookmarkBusy = true);

    try {
      String? error;
      var message = 'Opportunity saved';

      if (existingSaved != null) {
        error = await savedProvider.unsaveOpportunity(
          existingSaved.id,
          currentUser.uid,
        );
        message = 'Removed from saved opportunities';
      } else {
        error = await savedProvider.saveOpportunity(
          studentId: currentUser.uid,
          opportunityId: widget.opportunity.id,
          title: widget.opportunity.title,
          companyName: _companyName,
          type: _effectiveType,
          location: _locationValue,
          deadline: _deadlineLabel ?? '',
        );
      }

      if (!mounted) {
        return;
      }

      context.showAppSnackBar(
        error ?? message,
        title: error == null ? 'Saved items updated' : 'Save unavailable',
        type: error == null ? AppFeedbackType.success : AppFeedbackType.error,
      );
    } finally {
      if (mounted) {
        setState(() => _isBookmarkBusy = false);
      }
    }
  }

  Future<void> _shareOpportunity() async {
    final lines = <String>[
      widget.opportunity.title.trim().isEmpty
          ? 'Opportunity on AvenirDZ'
          : widget.opportunity.title.trim(),
      'Company: $_companyName',
      'Type: ${OpportunityType.label(_effectiveType)}',
      if (_locationValue.isNotEmpty) 'Location: $_locationValue',
      if (_salaryLabel != null) '$_primaryCompensationLabel: ${_salaryLabel!}',
      if (_durationLabel != null) 'Duration: ${_durationLabel!}',
      if (_deadlineLabel != null) 'Deadline: ${_deadlineLabel!}',
      '',
      'Shared from AvenirDZ',
    ];

    await SharePlus.instance.share(
      ShareParams(
        text: lines.join('\n'),
        subject: widget.opportunity.title.trim().isEmpty
            ? 'Opportunity from AvenirDZ'
            : widget.opportunity.title.trim(),
      ),
    );
  }

  String? get _appliedStatus {
    final userId = context.read<AuthProvider>().userModel?.uid;
    if (userId == null || userId.isEmpty) {
      return null;
    }
    return context.read<ApplicationProvider>().applicationStatusFor(
      widget.opportunity.id,
    );
  }

  String _buttonLabelForStatus(ApplicationEligibilityStatus status) {
    switch (status) {
      case ApplicationEligibilityStatus.requiresLogin:
        return 'Login to Apply';
      case ApplicationEligibilityStatus.available:
        return _effectiveType == OpportunityType.sponsoring
            ? 'Apply for Funding'
            : 'Apply Now';
      case ApplicationEligibilityStatus.alreadyApplied:
        final appStatus = _appliedStatus;
        if (appStatus != null) {
          return 'Status: ${ApplicationStatus.label(appStatus)}';
        }
        return 'Already Applied';
      case ApplicationEligibilityStatus.closed:
        return 'Opportunity Closed';
      case ApplicationEligibilityStatus.unavailable:
        return 'No Longer Available';
    }
  }

  String _messageForStatus(ApplicationEligibilityStatus status) {
    switch (status) {
      case ApplicationEligibilityStatus.requiresLogin:
        return 'You must be logged in to apply.';
      case ApplicationEligibilityStatus.available:
        return 'You can apply to this opportunity.';
      case ApplicationEligibilityStatus.alreadyApplied:
        return 'You have already applied to this opportunity.';
      case ApplicationEligibilityStatus.closed:
        return 'This opportunity is closed.';
      case ApplicationEligibilityStatus.unavailable:
        return 'This opportunity is no longer available.';
    }
  }

  String get _companyName {
    final companyName = widget.opportunity.companyName.trim();
    return companyName.isEmpty ? 'AvenirDZ partner' : companyName;
  }

  String get _locationValue {
    final location = widget.opportunity.location.trim();
    if (location.isNotEmpty) {
      return location;
    }
    return widget.opportunity.readString(<String>[
          'city',
          'region',
          'country',
          'officeLocation',
          'address',
        ]) ??
        '';
  }

  String? get _deadlineLabel {
    final deadline =
        widget.opportunity.applicationDeadline ??
        OpportunityMetadata.parseDateTimeLike(widget.opportunity.deadlineLabel);
    if (deadline != null) {
      return OpportunityMetadata.formatDateLabel(deadline);
    }
    final fallback = widget.opportunity.deadlineLabel.trim();
    return fallback.isEmpty ? null : fallback;
  }

  String get _primaryCompensationLabel =>
      _effectiveType == OpportunityType.sponsoring ? 'Funding' : 'Salary';

  String get _compensationNoteTitle =>
      _effectiveType == OpportunityType.sponsoring
          ? 'Funding note'
          : 'Compensation note';

  String? get _salaryLabel => OpportunityMetadata.formatSalaryRange(
    salaryMin: widget.opportunity.salaryMin,
    salaryMax: widget.opportunity.salaryMax,
    salaryCurrency: widget.opportunity.salaryCurrency,
    salaryPeriod: widget.opportunity.salaryPeriod,
  );

  String? get _compensationNote {
    final note = OpportunityMetadata.sanitizeText(
      widget.opportunity.compensationText,
    );
    if (note == null) {
      return null;
    }

    final salary = _salaryLabel;
    if (salary != null &&
        note.trim().toLowerCase() == salary.trim().toLowerCase()) {
      return null;
    }

    return note;
  }

  String? get _durationLabel {
    final normalizedDuration = OpportunityMetadata.normalizeDuration(
      widget.opportunity.duration,
    );
    if (normalizedDuration != null) {
      return normalizedDuration;
    }
    return OpportunityMetadata.normalizeDuration(
      _readText(<String>['programDuration', 'internshipDuration', 'timeline']),
    );
  }

  String? get _employmentTypeLabel => OpportunityMetadata.formatEmploymentType(
    widget.opportunity.employmentType,
  );

  String? get _workModeLabel =>
      OpportunityMetadata.formatWorkMode(widget.opportunity.workMode);

  String? get _experienceLevelLabel {
    final rawValue = _readText(<String>[
      'experienceLevel',
      'experience_level',
      'experience',
      'seniority',
      'careerStage',
      'level',
    ]);
    if (rawValue == null) {
      return null;
    }

    final normalized = rawValue
        .trim()
        .replaceAll(RegExp(r'[_-]+'), ' ')
        .replaceAll(RegExp(r'\s+'), ' ');
    if (normalized.isEmpty) {
      return null;
    }

    return normalized
        .split(' ')
        .where((part) => part.isNotEmpty)
        .map(
          (part) =>
              '${part[0].toUpperCase()}${part.substring(1).toLowerCase()}',
        )
        .join(' ');
  }

  String get _overviewTitle => _effectiveType == OpportunityType.sponsoring
      ? 'Program Overview'
      : 'Overview';

  String get _requirementsTitle => _effectiveType == OpportunityType.sponsoring
      ? 'Eligibility'
      : 'Requirements';

  List<String> get _explicitTags => OpportunityMetadata.stringListFromValue(
    widget.opportunity.firstValue(<String>[
      'tags',
      'tag',
      'labels',
      'badges',
      'badgeLabels',
      'highlightTags',
      'pills',
    ]),
    maxItems: 6,
  );

  List<String> get _explicitBenefits => OpportunityMetadata.stringListFromValue(
    widget.opportunity.firstValue(<String>[
      'benefits',
      'benefitList',
      'benefit_list',
      'perks',
      'perkList',
      'perk_list',
      'advantages',
      'offerings',
      'whatYouGet',
      'support',
    ]),
    maxItems: 8,
  );

  String? get _benefitsText => _readText(<String>[
    'benefitsText',
    'benefitsDescription',
    'perkDetails',
    'supportDetails',
  ]);

  List<String> get _heroTags => OpportunityMetadata.uniqueNonEmpty(<String?>[
    ..._explicitTags,
    _employmentTypeLabel,
    _workModeLabel,
    _experienceLevelLabel,
  ]).take(4).toList();

  String _displayStatusLabel(String rawValue) {
    final normalized = rawValue
        .trim()
        .replaceAll(RegExp(r'[_-]+'), ' ')
        .replaceAll(RegExp(r'\s+'), ' ');
    if (normalized.isEmpty) {
      return '';
    }

    return normalized
        .split(' ')
        .where((part) => part.isNotEmpty)
        .map(
          (part) =>
              '${part[0].toUpperCase()}${part.substring(1).toLowerCase()}',
        )
        .join(' ');
  }

  SavedOpportunityModel? _existingSavedOpportunity(
    SavedOpportunityProvider provider,
  ) {
    for (final item in provider.savedOpportunities) {
      if (item.opportunityId == widget.opportunity.id) {
        return item;
      }
    }
    return null;
  }

  String? _readText(List<String> keys) => widget.opportunity.readString(keys);

  DateTime? _readDate(List<String> keys) =>
      widget.opportunity.readDateTime(keys);

  List<String> _readList(List<String> keys, {int maxItems = 8}) {
    return OpportunityMetadata.stringListFromValue(
      widget.opportunity.firstValue(keys),
      maxItems: maxItems,
    );
  }

  String? get _externalLink => _readText(<String>[
    'applicationUrl',
    'applyUrl',
    'externalLink',
    'website',
    'link',
  ]);

  String? get _contactInfo => _readText(<String>[
    'contactEmail',
    'contactPhone',
    'contact',
    'contactInfo',
  ]);

  String? get _startDateLabel {
    final date = _readDate(<String>[
      'startDate',
      'programStartDate',
      'expectedStartDate',
      'beginsAt',
    ]);
    return date == null ? null : DateFormat('MMM d, yyyy').format(date);
  }

  Future<void> _openExternalLink(String value) async {
    final uri = Uri.tryParse(value.trim());
    if (uri == null) {
      return;
    }
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  @override
  Widget build(BuildContext context) {
    final savedProvider = context.watch<SavedOpportunityProvider>();
    final isSaved = _existingSavedOpportunity(savedProvider) != null;
    final applyBar = FutureBuilder<ApplicationEligibilityStatus>(
      future: _eligibilityFuture,
      builder: (context, snapshot) {
        final status = snapshot.data ?? ApplicationEligibilityStatus.available;
        final canApply = status == ApplicationEligibilityStatus.available;

        return SafeArea(
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
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  AppPrimaryButton(
                    theme: _theme,
                    label: _buttonLabelForStatus(status),
                    icon: canApply
                        ? Icons.send_rounded
                        : Icons.info_outline_rounded,
                    onPressed: canApply ? _apply : () => _refreshEligibility(),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: <Widget>[
                      Expanded(
                        child: AppSecondaryButton(
                          theme: _theme,
                          label: isSaved ? 'Saved' : 'Save',
                          icon: isSaved
                              ? Icons.bookmark_rounded
                              : Icons.bookmark_outline_rounded,
                          onPressed: _toggleSavedOpportunity,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: AppSecondaryButton(
                          theme: _theme,
                          label: 'Share',
                          icon: Icons.ios_share_rounded,
                          onPressed: _shareOpportunity,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );

    final scaffold = Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: _theme.textPrimary,
        title: Text(
          OpportunityType.label(_effectiveType),
          style: _theme.section(size: 18, weight: FontWeight.w700),
        ),
        actions: <Widget>[
          IconButton(
            tooltip: isSaved ? 'Unsave opportunity' : 'Save opportunity',
            onPressed: _toggleSavedOpportunity,
            icon: Icon(
              isSaved ? Icons.bookmark_rounded : Icons.bookmark_outline_rounded,
            ),
          ),
          IconButton(
            tooltip: 'Share opportunity',
            onPressed: _shareOpportunity,
            icon: const Icon(Icons.ios_share_rounded),
          ),
          const SizedBox(width: 6),
        ],
      ),
      bottomNavigationBar: applyBar,
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 132),
        children: <Widget>[
          AppDetailHeroCard(
            theme: _theme,
            icon: OpportunityType.icon(_effectiveType),
            title: widget.opportunity.title.trim().isEmpty
                ? 'Opportunity'
                : widget.opportunity.title.trim(),
            subtitle: _companyName,
            summary: widget.opportunity.description.trim(),
            badges: <AppBadgeData>[
              AppBadgeData(
                label: OpportunityType.label(_effectiveType),
                icon: OpportunityType.icon(_effectiveType),
              ),
              if (widget.opportunity.status.trim().isNotEmpty)
                AppBadgeData(
                  label: _displayStatusLabel(widget.opportunity.status),
                ),
              ..._heroTags.map((tag) => AppBadgeData(label: tag)),
            ],
            footer: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                AppMetaRow(
                  theme: _theme,
                  label: 'Location',
                  value: _locationValue,
                  icon: Icons.location_on_outlined,
                ),
                AppMetaRow(
                  theme: _theme,
                  label: 'Deadline',
                  value: _deadlineLabel ?? '',
                  icon: Icons.event_outlined,
                ),
                AppMetaRow(
                  theme: _theme,
                  label: 'Posted',
                  value: widget.opportunity.createdAt == null
                      ? ''
                      : DateFormat(
                          'MMM d, yyyy',
                        ).format(widget.opportunity.createdAt!.toDate()),
                  icon: Icons.schedule_outlined,
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          AppInfoTileGrid(
            theme: _theme,
            items: <AppInfoTileData>[
              AppInfoTileData(
                label: 'Type',
                value: OpportunityType.label(_effectiveType),
                icon: OpportunityType.icon(_effectiveType),
              ),
              AppInfoTileData(
                label: _primaryCompensationLabel,
                value: _salaryLabel ?? '',
                icon: Icons.payments_outlined,
                emphasize: _salaryLabel != null,
              ),
              AppInfoTileData(
                label: 'Location',
                value: _locationValue,
                icon: Icons.location_on_outlined,
              ),
              AppInfoTileData(
                label: 'Deadline',
                value: _deadlineLabel ?? '',
                icon: Icons.event_available_rounded,
              ),
              AppInfoTileData(
                label: 'Duration',
                value: _durationLabel ?? '',
                icon: Icons.schedule_outlined,
              ),
              AppInfoTileData(
                label: 'Work mode',
                value: _workModeLabel ?? '',
                icon: Icons.lan_outlined,
              ),
              AppInfoTileData(
                label: 'Employment',
                value: _employmentTypeLabel ?? '',
                icon: Icons.badge_outlined,
              ),
              AppInfoTileData(
                label: 'Experience',
                value: _experienceLevelLabel ?? '',
                icon: Icons.trending_up_rounded,
              ),
              AppInfoTileData(
                label: 'Start date',
                value: _startDateLabel ?? '',
                icon: Icons.play_circle_outline_rounded,
              ),
            ],
          ),
          if (_compensationNote != null) ...<Widget>[
            const SizedBox(height: 12),
            _OpportunityCompensationNote(
              theme: _theme,
              title: _compensationNoteTitle,
              note: _compensationNote!,
            ),
          ],
          const SizedBox(height: 16),
          AppDetailSection(
            theme: _theme,
            title: _overviewTitle,
            icon: Icons.description_outlined,
            child: Text(
              widget.opportunity.description.trim(),
              style: _theme.body(color: _theme.textPrimary),
            ),
          ),
          if (_readText(<String>[
                'responsibilities',
                'programOverview',
                'details',
              ]) !=
              null) ...<Widget>[
            const SizedBox(height: 16),
            AppDetailSection(
              theme: _theme,
              title: _effectiveType == OpportunityType.sponsoring
                  ? 'Program Details'
                  : 'Responsibilities',
              icon: Icons.checklist_rounded,
              child: _OpportunityTextOrList(
                theme: _theme,
                text:
                    _readText(<String>[
                      'responsibilities',
                      'programOverview',
                      'details',
                    ]) ??
                    '',
                items: _readList(<String>[
                  'responsibilityItems',
                  'responsibilitiesList',
                  'programHighlights',
                ]),
              ),
            ),
          ],
          const SizedBox(height: 16),
          AppDetailSection(
            theme: _theme,
            title: _requirementsTitle,
            icon: Icons.rule_folder_outlined,
            child: _OpportunityTextOrList(
              theme: _theme,
              text: widget.opportunity.requirements.trim(),
              items: widget.opportunity.requirementItems,
            ),
          ),
          if (_explicitBenefits.isNotEmpty ||
              _benefitsText != null) ...<Widget>[
            const SizedBox(height: 16),
            AppDetailSection(
              theme: _theme,
              title: 'Benefits',
              icon: Icons.workspace_premium_outlined,
              child: _OpportunityTextOrList(
                theme: _theme,
                text: _benefitsText ?? '',
                items: _explicitBenefits,
              ),
            ),
          ],
          if (_readText(<String>[
                'applicationProcess',
                'applicationInstructions',
                'howToApply',
              ]) !=
              null) ...<Widget>[
            const SizedBox(height: 16),
            AppDetailSection(
              theme: _theme,
              title: 'Application Process',
              icon: Icons.assignment_outlined,
              child: _OpportunityTextOrList(
                theme: _theme,
                text:
                    _readText(<String>[
                      'applicationProcess',
                      'applicationInstructions',
                      'howToApply',
                    ]) ??
                    '',
                items: _readList(<String>['applicationSteps', 'steps']),
              ),
            ),
          ],
          if (_readList(<String>[
            'skillsNeeded',
            'skills',
            'preferredSkills',
          ]).isNotEmpty) ...<Widget>[
            const SizedBox(height: 16),
            AppDetailSection(
              theme: _theme,
              title: 'Skills Needed',
              icon: Icons.auto_fix_high_outlined,
              child: _OpportunityChipWrap(
                theme: _theme,
                items: _readList(<String>[
                  'skillsNeeded',
                  'skills',
                  'preferredSkills',
                ]),
              ),
            ),
          ],
          const SizedBox(height: 16),
          AppDetailSection(
            theme: _theme,
            title: 'Additional Information',
            icon: Icons.info_outline_rounded,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                AppMetaRow(
                  theme: _theme,
                  label: 'Company',
                  value: _companyName,
                ),
                AppMetaRow(
                  theme: _theme,
                  label: 'Work mode',
                  value: _workModeLabel ?? '',
                ),
                AppMetaRow(
                  theme: _theme,
                  label: 'Employment type',
                  value: _employmentTypeLabel ?? '',
                ),
                AppMetaRow(
                  theme: _theme,
                  label: 'Experience level',
                  value: _experienceLevelLabel ?? '',
                ),
                AppMetaRow(
                  theme: _theme,
                  label: 'Paid status',
                  value:
                      OpportunityMetadata.formatPaidLabel(
                        widget.opportunity.isPaid,
                      ) ??
                      '',
                ),
                AppMetaRow(
                  theme: _theme,
                  label: _primaryCompensationLabel,
                  value: _salaryLabel ?? '',
                ),
                AppMetaRow(
                  theme: _theme,
                  label: 'Duration',
                  value: _durationLabel ?? '',
                ),
                AppMetaRow(
                  theme: _theme,
                  label: 'Start date',
                  value: _startDateLabel ?? '',
                ),
                AppMetaRow(
                  theme: _theme,
                  label: 'Contact',
                  value: _contactInfo ?? '',
                ),
                AppMetaRow(
                  theme: _theme,
                  label: 'External link',
                  value: _externalLink ?? '',
                ),
                if (_readList(<String>['attachments', 'documents']).isNotEmpty)
                  AppMetaRow(
                    theme: _theme,
                    label: 'Attachments',
                    value: _readList(<String>[
                      'attachments',
                      'documents',
                    ]).join(', '),
                  ),
              ],
            ),
          ),
          if (_explicitTags.isNotEmpty) ...<Widget>[
            const SizedBox(height: 16),
            AppDetailSection(
              theme: _theme,
              title: 'Tags',
              icon: Icons.local_offer_outlined,
              child: _OpportunityChipWrap(theme: _theme, items: _explicitTags),
            ),
          ],
          if (_externalLink != null &&
              _externalLink!.trim().isNotEmpty) ...<Widget>[
            const SizedBox(height: 16),
            AppDetailSection(
              theme: _theme,
              title: 'External Application',
              icon: Icons.open_in_new_rounded,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  AppMetaRow(
                    theme: _theme,
                    label: 'Link',
                    value: _externalLink!,
                    icon: Icons.link_rounded,
                  ),
                  const SizedBox(height: 8),
                  AppPrimaryButton(
                    theme: _theme,
                    label: 'Open Link',
                    icon: Icons.open_in_new_rounded,
                    onPressed: () => _openExternalLink(_externalLink!),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );

    if (widget.isSheet) {
      return Container(
        height: MediaQuery.sizeOf(context).height * 0.93,
        decoration: BoxDecoration(
          color: _theme.background,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        clipBehavior: Clip.antiAlias,
        child: scaffold,
      );
    }

    return AppShellBackground(child: scaffold);
  }
}

class _OpportunityCompensationNote extends StatelessWidget {
  final AppContentTheme theme;
  final String title;
  final String note;

  const _OpportunityCompensationNote({
    required this.theme,
    required this.title,
    required this.note,
  });

  @override
  Widget build(BuildContext context) {
    final trimmedNote = note.trim();
    if (trimmedNote.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.accentSoft.withValues(alpha: 0.56),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: theme.accent.withValues(alpha: 0.16)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: theme.accent.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              Icons.sticky_note_2_outlined,
              size: 15,
              color: theme.accent,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  title,
                  style: theme.label(
                    size: 11.3,
                    color: theme.accentDark,
                    weight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  trimmedNote,
                  style: theme.body(
                    size: 12.1,
                    color: theme.textSecondary,
                    weight: FontWeight.w500,
                    height: 1.45,
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

class _OpportunityTextOrList extends StatelessWidget {
  final AppContentTheme theme;
  final String text;
  final List<String> items;

  const _OpportunityTextOrList({
    required this.theme,
    required this.text,
    required this.items,
  });

  @override
  Widget build(BuildContext context) {
    final visibleItems = items.where((item) => item.trim().isNotEmpty).toList();
    if (visibleItems.isNotEmpty) {
      return Column(
        children: visibleItems
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

    return Text(text, style: theme.body(color: theme.textPrimary));
  }
}

class _OpportunityChipWrap extends StatelessWidget {
  final AppContentTheme theme;
  final List<String> items;

  const _OpportunityChipWrap({required this.theme, required this.items});

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: items
          .where((item) => item.trim().isNotEmpty)
          .map(
            (item) => AppTagChip(
              theme: theme,
              badge: AppBadgeData(label: item),
            ),
          )
          .toList(growable: false),
    );
  }
}
