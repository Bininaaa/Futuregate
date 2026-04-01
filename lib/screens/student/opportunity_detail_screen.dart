import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';

import '../../models/opportunity_model.dart';
import '../../models/saved_opportunity_model.dart';
import '../../providers/application_provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/cv_provider.dart';
import '../../providers/saved_opportunity_provider.dart';
import '../../services/application_service.dart';
import '../../utils/opportunity_metadata.dart';
import '../../utils/opportunity_type.dart';
import '../../widgets/opportunity_details/opportunity_details_widgets.dart';

class OpportunityDetailScreen extends StatelessWidget {
  final OpportunityModel opportunity;

  const OpportunityDetailScreen({super.key, required this.opportunity});

  @override
  Widget build(BuildContext context) {
    return OpportunityDetailsScreen(opportunity: opportunity);
  }
}

class OpportunityDetailsScreen extends StatefulWidget {
  final OpportunityModel opportunity;
  final String? type;

  const OpportunityDetailsScreen({
    super.key,
    required this.opportunity,
    this.type,
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

  OpportunityVisualTheme get _theme =>
      OpportunityVisualTheme.fromType(_effectiveType);

  @override
  void initState() {
    super.initState();
    _eligibilityFuture = _loadEligibility();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }
      _ensureSavedStateLoaded();
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

  void _refreshEligibility() {
    setState(() {
      _eligibilityFuture = _loadEligibility();
    });
  }

  Future<void> _apply() async {
    final authProvider = context.read<AuthProvider>();
    final applicationProvider = context.read<ApplicationProvider>();
    final cvProvider = context.read<CvProvider>();
    final messenger = ScaffoldMessenger.of(context);
    final currentUser = authProvider.userModel;

    if (currentUser == null) {
      messenger.showSnackBar(
        const SnackBar(content: Text('You must be logged in to apply')),
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
      messenger.showSnackBar(
        SnackBar(content: Text(_messageForStatus(eligibility))),
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
      messenger.showSnackBar(
        const SnackBar(content: Text('Please create your CV before applying')),
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

    messenger.showSnackBar(
      SnackBar(content: Text(error ?? 'Application submitted successfully')),
    );
    _refreshEligibility();
  }

  Future<void> _toggleSavedOpportunity() async {
    final authProvider = context.read<AuthProvider>();
    final savedProvider = context.read<SavedOpportunityProvider>();
    final messenger = ScaffoldMessenger.of(context);
    final currentUser = authProvider.userModel;

    if (_isBookmarkBusy) {
      return;
    }

    if (currentUser == null) {
      messenger.showSnackBar(
        const SnackBar(content: Text('You must be logged in to save this')),
      );
      return;
    }

    final existingSaved = _existingSavedOpportunity(savedProvider);

    setState(() {
      _isBookmarkBusy = true;
    });

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

      messenger.showSnackBar(SnackBar(content: Text(error ?? message)));
    } finally {
      if (mounted) {
        setState(() {
          _isBookmarkBusy = false;
        });
      }
    }
  }

  Future<void> _shareOpportunity() async {
    final compensationLabel = _compensationLabel;
    final deadlineLabel = _deadlineLabel;
    final durationLabel = _durationLabel;
    final shareLines = <String>[
      widget.opportunity.title.trim().isEmpty
          ? 'Opportunity on AvenirDZ'
          : widget.opportunity.title.trim(),
      'Company: $_companyName',
      'Type: ${OpportunityType.label(_effectiveType)}',
      if (_locationValue.isNotEmpty) 'Location: $_locationValue',
      if (compensationLabel != null) 'Compensation: $compensationLabel',
      if (durationLabel != null) 'Duration: $durationLabel',
      if (deadlineLabel != null) 'Deadline: $deadlineLabel',
      '',
      'Shared from AvenirDZ',
    ];

    await SharePlus.instance.share(
      ShareParams(
        text: shareLines.join('\n'),
        subject: widget.opportunity.title.trim().isEmpty
            ? 'Opportunity from AvenirDZ'
            : widget.opportunity.title.trim(),
      ),
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
        return 'You must be logged in to apply';
      case ApplicationEligibilityStatus.available:
        return 'You can apply to this opportunity';
      case ApplicationEligibilityStatus.alreadyApplied:
        return 'You have already applied to this opportunity';
      case ApplicationEligibilityStatus.closed:
        return 'This opportunity is closed';
      case ApplicationEligibilityStatus.unavailable:
        return 'This opportunity is no longer available';
    }
  }

  String get _companyName {
    final companyName = widget.opportunity.companyName.trim();
    return companyName.isEmpty ? 'AvenirDZ partner' : companyName;
  }

  String get _companyInitial {
    final normalized = _companyName.trim();
    return normalized.isEmpty ? 'A' : normalized[0].toUpperCase();
  }

  String get _locationValue {
    final location = widget.opportunity.location.trim();
    if (location.isNotEmpty) {
      return location;
    }

    return widget.opportunity.readString([
          'city',
          'region',
          'country',
          'officeLocation',
          'address',
          'place',
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

  String? get _compensationLabel {
    final structuredLabel = OpportunityMetadata.buildCompensationLabel(
      salaryMin: widget.opportunity.salaryMin,
      salaryMax: widget.opportunity.salaryMax,
      salaryCurrency: widget.opportunity.salaryCurrency,
      salaryPeriod: widget.opportunity.salaryPeriod,
      compensationText: widget.opportunity.compensationText,
      isPaid: widget.opportunity.isPaid,
      preferCompensationText: true,
    );
    if (structuredLabel != null) {
      return structuredLabel;
    }

    final legacyLabel = OpportunityMetadata.extractCompensationText(
      widget.opportunity.rawData,
    );
    if (legacyLabel != null && legacyLabel.trim().isNotEmpty) {
      return legacyLabel.trim();
    }

    return null;
  }

  String? get _durationLabel {
    final normalizedDuration = OpportunityMetadata.normalizeDuration(
      widget.opportunity.duration,
    );
    if (normalizedDuration != null) {
      return normalizedDuration;
    }

    final fallback = widget.opportunity.readString([
      'programDuration',
      'internshipDuration',
      'timeline',
    ]);
    return OpportunityMetadata.normalizeDuration(fallback);
  }

  String? get _employmentTypeLabel => OpportunityMetadata.formatEmploymentType(
    widget.opportunity.employmentType,
  );

  String? get _workModeLabel =>
      OpportunityMetadata.formatWorkMode(widget.opportunity.workMode);

  bool get _isBeginnerFriendly {
    if (_effectiveType != OpportunityType.internship) {
      return false;
    }

    final searchable = [
      widget.opportunity.title,
      widget.opportunity.description,
      widget.opportunity.requirements,
      widget.opportunity.readString([
            'experienceLevel',
            'experience_level',
            'careerStage',
            'level',
            'tag',
          ]) ??
          '',
    ].join(' ').toLowerCase();

    return searchable.contains('beginner') ||
        searchable.contains('junior') ||
        searchable.contains('entry') ||
        searchable.contains('student');
  }

  String? get _heroBadgeLabel {
    final lowerCompensation = _compensationLabel?.toLowerCase() ?? '';

    if (_effectiveType == OpportunityType.internship && _isBeginnerFriendly) {
      return 'Beginner Friendly';
    }

    if (_effectiveType == OpportunityType.sponsoring) {
      if (lowerCompensation.contains('fully funded') ||
          lowerCompensation.contains('full funding')) {
        return 'FULLY FUNDED';
      }
      if (widget.opportunity.isFeatured) {
        return 'FEATURED';
      }
      return _theme.highlightBadge;
    }

    return null;
  }

  List<String> get _heroTags {
    final highlightBadge = _heroBadgeLabel?.toLowerCase();
    return OpportunityMetadata.uniqueNonEmpty(
      widget.opportunity.tags,
    ).where((tag) => tag.toLowerCase() != highlightBadge).take(4).toList();
  }

  List<String> get _requirementItems {
    if (widget.opportunity.requirementItems.isNotEmpty) {
      return widget.opportunity.requirementItems.take(6).toList();
    }

    return const [];
  }

  List<String> get _benefitItems {
    if (widget.opportunity.benefits.isNotEmpty) {
      return widget.opportunity.benefits.take(6).toList();
    }

    return const [];
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

  List<_OpportunityInfoCardData> _buildInfoCards() {
    final cards = <_OpportunityInfoCardData>[];
    final compensationLabel = _compensationLabel;
    final durationLabel = _durationLabel;
    final deadlineLabel = _deadlineLabel;

    if (compensationLabel != null && compensationLabel.trim().isNotEmpty) {
      cards.add(
        _OpportunityInfoCardData(
          icon: _compensationIcon,
          label: _compensationCardLabel,
          value: compensationLabel,
          highlighted: _theme.emphasizeCompensation,
        ),
      );
    }

    if (_locationValue.isNotEmpty) {
      cards.add(
        _OpportunityInfoCardData(
          icon: _locationIcon,
          label: 'Location',
          value: _locationValue,
        ),
      );
    }

    final timelineValue =
        durationLabel ??
        _workModeLabel ??
        _employmentTypeLabel ??
        deadlineLabel;
    if (timelineValue != null && timelineValue.trim().isNotEmpty) {
      cards.add(
        _OpportunityInfoCardData(
          icon: _durationIcon,
          label: durationLabel != null
              ? 'Duration'
              : _workModeLabel != null
              ? 'Work Mode'
              : _employmentTypeLabel != null
              ? 'Schedule'
              : 'Deadline',
          value: timelineValue,
        ),
      );
    }

    return cards;
  }

  String get _descriptionTitle {
    switch (_effectiveType) {
      case OpportunityType.internship:
        return 'Internship Overview';
      case OpportunityType.sponsoring:
        return 'Program Description';
      case OpportunityType.job:
      default:
        return 'Job Description';
    }
  }

  String get _requirementsTitle {
    return OpportunityType.requirementsLabel(_effectiveType);
  }

  String get _descriptionText {
    final text = widget.opportunity.description.trim();
    return text.isEmpty ? 'No description provided.' : text;
  }

  String get _compensationCardLabel {
    if (_effectiveType == OpportunityType.sponsoring) {
      return 'Funding';
    }
    if (_effectiveType == OpportunityType.internship) {
      return 'Stipend';
    }
    return 'Salary';
  }

  IconData get _compensationIcon {
    switch (_effectiveType) {
      case OpportunityType.internship:
        return Icons.rocket_launch_rounded;
      case OpportunityType.sponsoring:
        return Icons.workspace_premium_rounded;
      case OpportunityType.job:
      default:
        return Icons.account_balance_wallet_outlined;
    }
  }

  IconData get _locationIcon {
    switch (_effectiveType) {
      case OpportunityType.internship:
        return Icons.explore_rounded;
      case OpportunityType.sponsoring:
        return Icons.public_rounded;
      case OpportunityType.job:
      default:
        return Icons.location_on_outlined;
    }
  }

  IconData get _durationIcon {
    switch (_effectiveType) {
      case OpportunityType.internship:
        return Icons.auto_awesome_rounded;
      case OpportunityType.sponsoring:
        return Icons.hourglass_bottom_rounded;
      case OpportunityType.job:
      default:
        return Icons.schedule_outlined;
    }
  }

  IconData _requirementIconForIndex(int index) {
    switch (_effectiveType) {
      case OpportunityType.internship:
        return const [
          Icons.school_rounded,
          Icons.lightbulb_outline_rounded,
          Icons.group_outlined,
          Icons.track_changes_rounded,
        ][index % 4];
      case OpportunityType.sponsoring:
        return const [
          Icons.verified_outlined,
          Icons.article_outlined,
          Icons.stars_rounded,
          Icons.workspace_premium_outlined,
        ][index % 4];
      case OpportunityType.job:
      default:
        return const [
          Icons.check_circle_outline_rounded,
          Icons.badge_outlined,
          Icons.auto_awesome_motion_outlined,
          Icons.rule_folder_outlined,
        ][index % 4];
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = _theme;
    final savedProvider = context.watch<SavedOpportunityProvider>();
    final authProvider = context.watch<AuthProvider>();
    final applicationProvider = context.watch<ApplicationProvider>();
    final isSaved = _existingSavedOpportunity(savedProvider) != null;
    final canShowBookmark = authProvider.userModel != null;
    final infoCards = _buildInfoCards();

    return Scaffold(
      backgroundColor: theme.pageBackground,
      bottomNavigationBar: SafeArea(
        top: false,
        child: FutureBuilder<ApplicationEligibilityStatus>(
          future: _eligibilityFuture,
          builder: (context, snapshot) {
            final eligibility =
                snapshot.data ?? ApplicationEligibilityStatus.available;
            final isCheckingEligibility =
                snapshot.connectionState == ConnectionState.waiting;
            final canApply =
                eligibility == ApplicationEligibilityStatus.available &&
                !applicationProvider.isLoading &&
                !isCheckingEligibility;

            return ApplyBar(
              theme: theme,
              onShare: _shareOpportunity,
              onApply: canApply ? _apply : null,
              applyLabel: isCheckingEligibility
                  ? 'Checking...'
                  : _buttonLabelForStatus(eligibility),
              isBusy: applicationProvider.isLoading || isCheckingEligibility,
            );
          },
        ),
      ),
      body: Column(
        children: [
          SafeArea(
            bottom: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 10, 12, 6),
              child: Row(
                children: [
                  _TopBarIconButton(
                    icon: Icons.arrow_back_ios_new_rounded,
                    onTap: () => Navigator.of(context).maybePop(),
                  ),
                  Expanded(
                    child: Text(
                      'AvenirDZ',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: theme.primaryTextColor,
                      ),
                    ),
                  ),
                  _TopBarIconButton(
                    icon: isSaved
                        ? Icons.bookmark_rounded
                        : Icons.bookmark_border_rounded,
                    onTap: canShowBookmark ? _toggleSavedOpportunity : null,
                    isBusy: _isBookmarkBusy,
                    iconColor: isSaved
                        ? theme.accentDeepColor
                        : theme.primaryTextColor,
                    fillColor: isSaved
                        ? theme.accentSoftColor
                        : theme.surfaceColor,
                  ),
                ],
              ),
            ),
          ),
          Expanded(
            child: CustomScrollView(
              physics: const BouncingScrollPhysics(
                parent: AlwaysScrollableScrollPhysics(),
              ),
              keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
              slivers: [
                SliverToBoxAdapter(
                  child: OpportunityHeader(
                    theme: theme,
                    tags: _heroTags,
                    title: widget.opportunity.title.trim().isEmpty
                        ? 'Opportunity'
                        : widget.opportunity.title.trim(),
                    company: _companyName,
                    highlightBadge: _heroBadgeLabel,
                    companyInitial: _companyInitial,
                  ),
                ),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 14, 16, 92),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (infoCards.isNotEmpty) ...[
                          ...infoCards.map(
                            (card) => Padding(
                              padding: const EdgeInsets.only(bottom: 10),
                              child: InfoCard(
                                theme: theme,
                                icon: card.icon,
                                label: card.label,
                                value: card.value,
                                isHighlighted: card.highlighted,
                              ),
                            ),
                          ),
                          const SizedBox(height: 10),
                        ],
                        _SectionCard(
                          theme: theme,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              SectionTitle(
                                theme: theme,
                                title: _descriptionTitle,
                              ),
                              const SizedBox(height: 12),
                              Text(
                                _descriptionText,
                                style: GoogleFonts.poppins(
                                  fontSize: 12.75,
                                  height: 1.62,
                                  color: theme.secondaryTextColor,
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (_requirementItems.isNotEmpty) ...[
                          const SizedBox(height: 16),
                          _SectionCard(
                            theme: theme,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                SectionTitle(
                                  theme: theme,
                                  title: _requirementsTitle,
                                ),
                                const SizedBox(height: 12),
                                ..._requirementItems.asMap().entries.map(
                                  (entry) => Padding(
                                    padding: EdgeInsets.only(
                                      bottom:
                                          entry.key ==
                                              _requirementItems.length - 1
                                          ? 0
                                          : 8,
                                    ),
                                    child: RequirementItem(
                                      theme: theme,
                                      text: entry.value,
                                      icon: _requirementIconForIndex(entry.key),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                        if (_benefitItems.isNotEmpty) ...[
                          const SizedBox(height: 16),
                          _SectionCard(
                            theme: theme,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                SectionTitle(theme: theme, title: 'Benefits'),
                                const SizedBox(height: 12),
                                ..._benefitItems.asMap().entries.map(
                                  (entry) => Padding(
                                    padding: EdgeInsets.only(
                                      bottom:
                                          entry.key == _benefitItems.length - 1
                                          ? 0
                                          : 10,
                                    ),
                                    child: BenefitItem(
                                      theme: theme,
                                      text: entry.value,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ],
                    ),
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

class _SectionCard extends StatelessWidget {
  final OpportunityVisualTheme theme;
  final Widget child;

  const _SectionCard({required this.theme, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.surfaceColor,
        borderRadius: BorderRadius.circular(theme.cardRadius),
        boxShadow: [
          BoxShadow(
            color: theme.shadowColor.withValues(alpha: 0.18),
            blurRadius: theme.shadowBlur - 4,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: child,
    );
  }
}

class _TopBarIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onTap;
  final bool isBusy;
  final Color? iconColor;
  final Color? fillColor;

  const _TopBarIconButton({
    required this.icon,
    required this.onTap,
    this.isBusy = false,
    this.iconColor,
    this.fillColor,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: isBusy ? null : onTap,
        borderRadius: BorderRadius.circular(14),
        child: Ink(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: fillColor ?? Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: const Color(0xFFE2E8F0)),
          ),
          child: Center(
            child: isBusy
                ? SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.2,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        iconColor ?? const Color(0xFF0F172A),
                      ),
                    ),
                  )
                : Icon(
                    icon,
                    size: 18,
                    color: iconColor ?? const Color(0xFF0F172A),
                  ),
          ),
        ),
      ),
    );
  }
}

class _OpportunityInfoCardData {
  final IconData icon;
  final String label;
  final String value;
  final bool highlighted;

  const _OpportunityInfoCardData({
    required this.icon,
    required this.label,
    required this.value,
    this.highlighted = false,
  });
}
