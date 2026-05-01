import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../models/opportunity_model.dart';
import '../../models/saved_opportunity_model.dart';
import '../../models/student_application_item_model.dart';
import '../../providers/application_provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/chat_provider.dart';
import '../../providers/cv_provider.dart';
import '../../providers/saved_opportunity_provider.dart';
import '../../services/application_service.dart';
import '../../theme/app_colors.dart';
import '../../utils/application_status.dart';
import '../../utils/content_language.dart';
import '../../utils/display_text.dart';
import '../../utils/localized_display.dart';
import '../../utils/opportunity_metadata.dart';
import '../../utils/opportunity_type.dart';
import '../../widgets/app_shell_background.dart';
import '../../widgets/shared/app_content_system.dart';
import '../../widgets/shared/app_directional.dart';
import '../../widgets/shared/app_feedback.dart';
import '../chat/user_profile_preview_screen.dart';
import 'chat_screen.dart';
import '../../l10n/generated/app_localizations.dart';
import '../../providers/subscription_provider.dart';
import '../../widgets/early_access_label.dart';
import '../../widgets/premium_upgrade_modal.dart';
import '../../widgets/saved_limit_upgrade_modal.dart';
import 'premium_pass_screen.dart';

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
  bool _isApplying = false;
  bool _isWithdrawing = false;
  bool _isChatOpening = false;

  String get _effectiveType =>
      OpportunityType.parse(widget.type ?? widget.opportunity.type);

  AppContentTheme get _theme {
    switch (_effectiveType) {
      case OpportunityType.internship:
        return AppContentTheme.futureGate(
          accent: AppColors.current.secondary,
          accentDark: AppColors.current.primaryDeep,
          accentSoft: AppColors.current.secondarySoft,
          secondary: AppColors.current.primary,
          heroGradient: LinearGradient(
            colors: <Color>[
              AppColors.current.secondary,
              AppColors.current.primary,
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        );
      case OpportunityType.sponsoring:
        return AppContentTheme.futureGate(
          accent: AppColors.current.accent,
          accentDark: AppColors.current.primaryDeep,
          accentSoft: AppColors.current.accentSoft,
          secondary: AppColors.current.primary,
          heroGradient: LinearGradient(
            colors: <Color>[
              AppColors.current.primaryDeep,
              AppColors.current.accent,
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        );
      case OpportunityType.job:
      default:
        return AppContentTheme.futureGate(
          accent: AppColors.current.primary,
          accentDark: AppColors.current.primaryDeep,
          accentSoft: AppColors.current.primarySoft,
          secondary: AppColors.current.secondary,
          heroGradient: LinearGradient(
            colors: <Color>[
              AppColors.current.primary,
              AppColors.current.primaryDeep,
            ],
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
      if (!mounted) return;
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
    if (_isApplying) {
      return;
    }

    final authProvider = context.read<AuthProvider>();
    final applicationProvider = context.read<ApplicationProvider>();
    final cvProvider = context.read<CvProvider>();
    final currentUser = authProvider.userModel;

    if (currentUser == null) {
      context.showAppSnackBar(
        AppLocalizations.of(context)!.studentSignInContinueApplication,
        title: AppLocalizations.of(context)!.uiLoginRequired,
        type: AppFeedbackType.warning,
      );
      return;
    }

    // Check early access lock before doing anything expensive.
    if (widget.opportunity.isEarlyAccessActive) {
      final sub = context.read<SubscriptionProvider>().subscription;
      final isPremium = sub?.isActive ?? false;
      if (!isPremium) {
        final l10n = AppLocalizations.of(context)!;
        final goUpgrade = await showPremiumUpgradeModal(
          context,
          title: l10n.earlyAccessLockedModalTitle,
          body: l10n.earlyAccessLockedModalBody,
          highlightText: l10n.earlyAccessLockedMessage,
          onUpgrade: () => Navigator.of(
            context,
          ).push(MaterialPageRoute(builder: (_) => const PremiumPassScreen())),
        );
        if (!goUpgrade) return;
        // Re-check after return from premium screen.
        if (!mounted) return;
        final subNow = context.read<SubscriptionProvider>().subscription;
        if (!(subNow?.isActive ?? false)) return;
      }
    }

    setState(() => _isApplying = true);

    try {
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
          title: AppLocalizations.of(context)!.uiApplicationBlocked,
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
          AppLocalizations.of(context)!.studentCreateCvBeforeApplying,
          title: AppLocalizations.of(context)!.uiCvRequired,
          type: AppFeedbackType.warning,
        );
        return;
      }

      String? error;
      try {
        error = await applicationProvider.applyToOpportunity(
          studentId: currentUser.uid,
          studentName: currentUser.fullName,
          opportunityId: widget.opportunity.id,
          cvId: cv.id,
        );
      } on EarlyAccessLockedException {
        if (!mounted) return;
        final l10n = AppLocalizations.of(context)!;
        await showPremiumUpgradeModal(
          context,
          title: l10n.earlyAccessLockedModalTitle,
          body: l10n.earlyAccessLockedModalBody,
          onUpgrade: () => Navigator.of(
            context,
          ).push(MaterialPageRoute(builder: (_) => const PremiumPassScreen())),
        );
        return;
      }

      if (!mounted) {
        return;
      }

      context.showAppSnackBar(
        error ??
            AppLocalizations.of(context)!.studentApplicationSubmittedSuccess,
        title: error == null
            ? AppLocalizations.of(context)!.studentApplicationSentTitle
            : AppLocalizations.of(context)!.uiApplicationUnavailable,
        type: error == null ? AppFeedbackType.success : AppFeedbackType.error,
      );
      _refreshEligibility();
    } finally {
      if (mounted) {
        setState(() => _isApplying = false);
      }
    }
  }

  Future<void> _withdraw() async {
    if (_isWithdrawing) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(
          AppLocalizations.of(context)!.studentWithdrawApplicationTitle,
        ),
        content: Text(
          AppLocalizations.of(context)!.studentWithdrawApplicationMessage,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(AppLocalizations.of(context)!.cancelLabel),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: TextButton.styleFrom(
              foregroundColor: AppColors.current.danger,
            ),
            child: Text(AppLocalizations.of(context)!.studentWithdraw),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    final currentUser = context.read<AuthProvider>().userModel;
    if (currentUser == null) return;

    setState(() => _isWithdrawing = true);
    try {
      final error = await context
          .read<ApplicationProvider>()
          .withdrawApplication(
            studentId: currentUser.uid,
            opportunityId: widget.opportunity.id,
          );

      if (!mounted) return;

      context.showAppSnackBar(
        error ??
            AppLocalizations.of(context)!.studentApplicationWithdrawnSuccess,
        title: error == null
            ? AppLocalizations.of(context)!.uiApplicationWithdrawn
            : AppLocalizations.of(context)!.studentWithdrawalFailedTitle,
        type: error == null ? AppFeedbackType.removed : AppFeedbackType.error,
        icon: error == null ? Icons.undo_rounded : null,
      );

      if (error == null) _refreshEligibility();
    } finally {
      if (mounted) setState(() => _isWithdrawing = false);
    }
  }

  Future<void> _toggleSavedOpportunity() async {
    final authProvider = context.read<AuthProvider>();
    final savedProvider = context.read<SavedOpportunityProvider>();
    final currentUser = authProvider.userModel;
    final l10n = AppLocalizations.of(context)!;

    if (_isBookmarkBusy) {
      return;
    }
    if (currentUser == null) {
      context.showAppSnackBar(
        l10n.studentSignInSaveOpportunities,
        title: l10n.uiLoginRequired,
        type: AppFeedbackType.warning,
      );
      return;
    }

    final existingSaved = _existingSavedOpportunity(savedProvider);
    setState(() => _isBookmarkBusy = true);

    try {
      String? error;
      var message = l10n.studentOpportunitySaved;

      if (existingSaved != null) {
        error = await savedProvider.unsaveOpportunity(
          existingSaved.id,
          currentUser.uid,
        );
        message = l10n.studentRemovedFromSavedOpportunities;
      } else {
        final savedTitle = DisplayText.opportunityTitle(
          widget.opportunity.title,
          fallback: l10n.uiOpportunity,
        );
        try {
          error = await savedProvider.saveOpportunity(
            studentId: currentUser.uid,
            opportunityId: widget.opportunity.id,
            title: savedTitle,
            companyName: _companyName,
            type: _effectiveType,
            location: _locationValue,
            deadline: _deadlineLabel ?? '',
            fundingLabel: _effectiveType == OpportunityType.sponsoring
                ? widget.opportunity.fundingLabel() ?? ''
                : '',
          );
        } on SavedLimitReachedException catch (e) {
          if (!mounted) return;
          await showSavedLimitUpgradeModal(
            context,
            limit: e.limit,
            onUpgrade: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const PremiumPassScreen()),
            ),
          );
          return;
        } catch (e) {
          error = e.toString();
        }
      }

      if (!mounted) {
        return;
      }

      if (error == null && existingSaved == null) {
        final showedLimit = await showSavedLimitReachedAfterSave(
          context,
          currentCount: savedProvider.savedOpportunities.length,
          onUpgrade: () => Navigator.of(
            context,
          ).push(MaterialPageRoute(builder: (_) => const PremiumPassScreen())),
        );
        if (showedLimit || !mounted) {
          return;
        }
      }

      context.showAppSnackBar(
        error ?? message,
        title: error == null
            ? l10n.trainingSavedUpdatedTitle
            : l10n.uiSaveUnavailable,
        type: error == null
            ? (existingSaved != null
                  ? AppFeedbackType.removed
                  : AppFeedbackType.success)
            : AppFeedbackType.error,
        icon: error == null && existingSaved != null
            ? Icons.bookmark_remove_outlined
            : null,
      );
    } finally {
      if (mounted) {
        setState(() => _isBookmarkBusy = false);
      }
    }
  }

  Future<void> _shareOpportunity() async {
    final shareTitle = DisplayText.opportunityTitle(
      widget.opportunity.title,
      fallback: AppLocalizations.of(context)!.studentShareOpportunitySubject,
    );
    final lines = <String>[
      shareTitle,
      AppLocalizations.of(context)!.studentShareCompanyLine(_companyName),
      AppLocalizations.of(context)!.studentShareTypeLine(
        OpportunityType.label(_effectiveType, AppLocalizations.of(context)!),
      ),
      if (_locationValue.isNotEmpty)
        AppLocalizations.of(context)!.studentShareLocationLine(_locationValue),
      if (_salaryLabel != null) '$_primaryCompensationLabel: ${_salaryLabel!}',
      if (_durationLabel != null)
        AppLocalizations.of(context)!.studentShareDurationLine(_durationLabel!),
      if (_deadlineLabel != null)
        AppLocalizations.of(context)!.studentShareDeadlineLine(_deadlineLabel!),
      '',
      AppLocalizations.of(context)!.studentSharedFromFutureGate,
    ];

    await SharePlus.instance.share(
      ShareParams(text: lines.join('\n'), subject: shareTitle),
    );
  }

  Future<void> _openCompanyChat() async {
    if (_isChatOpening) {
      return;
    }

    if (widget.opportunity.isAdminPosted) {
      context.showAppSnackBar(
        AppLocalizations.of(context)!.uiTheCompanyWillContactYouByEmailSoon,
        title: AppLocalizations.of(context)!.uiApplicationApprovedB0Cb,
        type: AppFeedbackType.info,
      );
      return;
    }

    final currentUser = context.read<AuthProvider>().userModel;
    if (currentUser == null) {
      context.showAppSnackBar(
        AppLocalizations.of(context)!.studentSignInChatCompany,
        title: AppLocalizations.of(context)!.uiLoginRequired,
        type: AppFeedbackType.warning,
      );
      return;
    }

    final applicationProvider = context.read<ApplicationProvider>();
    final acceptedApplication = _acceptedApplication(applicationProvider);
    final companyId =
        acceptedApplication?.application.companyId.trim().isNotEmpty == true
        ? acceptedApplication!.application.companyId.trim()
        : widget.opportunity.companyId.trim();

    if (companyId.isEmpty) {
      context.showAppSnackBar(
        AppLocalizations.of(
          context,
        )!.uiCompanyDetailsAreMissingForThisOpportunity,
        title: AppLocalizations.of(context)!.uiChatUnavailable,
        type: AppFeedbackType.error,
      );
      return;
    }

    setState(() => _isChatOpening = true);

    try {
      final chatProvider = context.read<ChatProvider>();
      final conversation = await chatProvider.getOrCreateConversation(
        studentId: currentUser.uid,
        studentName: currentUser.fullName,
        companyId: companyId,
        companyName: _companyName,
        contextType: 'application',
        contextLabel: AppLocalizations.of(context)!.uiApplicationConversation,
        currentUserId: currentUser.uid,
        currentUserRole: currentUser.role,
      );

      if (!mounted) {
        return;
      }

      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => ChatScreen(
            conversationId: conversation.id,
            otherName: conversation.companyName,
            recipientId: conversation.companyId,
            otherRole: 'company',
            contextLabel: AppLocalizations.of(
              context,
            )!.uiApplicationConversation,
          ),
        ),
      );
    } catch (error) {
      if (!mounted) {
        return;
      }

      context.showAppSnackBar(
        AppLocalizations.of(context)!.uiCouldNotOpenChatValue(error),
        title: AppLocalizations.of(context)!.uiChatUnavailable,
        type: AppFeedbackType.error,
      );
    } finally {
      if (mounted) {
        setState(() => _isChatOpening = false);
      }
    }
  }

  Future<void> _openPublisherProfile() async {
    final publisherId = widget.opportunity.companyId.trim();
    if (publisherId.isEmpty) {
      context.showAppSnackBar(
        AppLocalizations.of(context)!.studentPublisherUnavailableMessage,
        title: AppLocalizations.of(context)!.studentPublisherUnavailableTitle,
        type: AppFeedbackType.info,
      );
      return;
    }

    await showFloatingUserProfilePreview(
      context,
      userId: publisherId,
      fallbackName: _companyName,
      fallbackRole: widget.opportunity.isAdminPosted ? 'admin' : 'company',
      fallbackHeadline: widget.opportunity.isAdminPosted
          ? AppLocalizations.of(context)!.studentFutureGatePublisher
          : AppLocalizations.of(context)!.studentOpportunityPublisher,
      fallbackAbout: AppLocalizations.of(
        context,
      )!.studentPublisherProfileFallbackAbout,
      fallbackLocation: _locationValue,
      contextLabel: OpportunityType.label(
        _effectiveType,
        AppLocalizations.of(context)!,
      ),
    );
  }

  StudentApplicationItemModel? _submittedApplication(
    ApplicationProvider provider,
  ) {
    for (final item in provider.submittedApplications) {
      if (item.opportunityId == widget.opportunity.id) {
        return item;
      }
    }

    return null;
  }

  StudentApplicationItemModel? _acceptedApplication(
    ApplicationProvider provider,
  ) {
    final item = _submittedApplication(provider);
    if (item == null ||
        ApplicationStatus.parse(item.status) != ApplicationStatus.accepted) {
      return null;
    }

    return item;
  }

  String? _appliedStatusFor(ApplicationProvider provider) {
    final userId = context.read<AuthProvider>().userModel?.uid;
    if (userId == null || userId.isEmpty) {
      return null;
    }

    return provider.applicationStatusFor(widget.opportunity.id);
  }

  String _buttonLabelForStatus(
    ApplicationEligibilityStatus status,
    ApplicationProvider applicationProvider,
  ) {
    switch (status) {
      case ApplicationEligibilityStatus.requiresLogin:
        return AppLocalizations.of(context)!.studentLoginToApply;
      case ApplicationEligibilityStatus.available:
        if (widget.opportunity.isEarlyAccessActive) {
          return '⚡ Claim Your Spot Now';
        }
        return _effectiveType == OpportunityType.sponsoring
            ? AppLocalizations.of(context)!.studentApplyForFunding
            : AppLocalizations.of(context)!.uiApplyNow;
      case ApplicationEligibilityStatus.alreadyApplied:
        final appStatus = _appliedStatusFor(applicationProvider);
        if (appStatus != null) {
          return AppLocalizations.of(context)!.studentStatusWithValue(
            ApplicationStatus.label(appStatus, AppLocalizations.of(context)!),
          );
        }
        return AppLocalizations.of(context)!.studentAlreadyApplied;
      case ApplicationEligibilityStatus.closed:
        return AppLocalizations.of(context)!.studentOpportunityClosed;
      case ApplicationEligibilityStatus.unavailable:
        return AppLocalizations.of(context)!.studentNoLongerAvailable;
    }
  }

  String _messageForStatus(ApplicationEligibilityStatus status) {
    switch (status) {
      case ApplicationEligibilityStatus.requiresLogin:
        return AppLocalizations.of(context)!.studentMustBeLoggedInApply;
      case ApplicationEligibilityStatus.available:
        return AppLocalizations.of(context)!.studentCanApplyOpportunity;
      case ApplicationEligibilityStatus.alreadyApplied:
        return AppLocalizations.of(context)!.studentAlreadyAppliedOpportunity;
      case ApplicationEligibilityStatus.closed:
        return AppLocalizations.of(context)!.studentOpportunityClosedMessage;
      case ApplicationEligibilityStatus.unavailable:
        return AppLocalizations.of(
          context,
        )!.studentOpportunityUnavailableMessage;
    }
  }

  String get _companyName {
    final companyName = widget.opportunity.companyName.trim();
    return companyName.isEmpty
        ? AppLocalizations.of(context)!.opportunityFutureGatePartner
        : companyName;
  }

  String get _locationValue {
    final location = widget.opportunity.location.trim();
    if (location.isNotEmpty) {
      return LocalizedDisplay.metadataLabel(context, location);
    }
    final fallback =
        widget.opportunity.readString(<String>[
          'city',
          'region',
          'country',
          'officeLocation',
          'address',
        ]) ??
        '';
    return LocalizedDisplay.metadataLabel(context, fallback);
  }

  String? get _deadlineLabel {
    final deadline =
        widget.opportunity.applicationDeadline ??
        OpportunityMetadata.parseDateTimeLike(widget.opportunity.deadlineLabel);
    if (deadline != null) {
      return LocalizedDisplay.shortDate(context, deadline, includeYear: true);
    }
    final fallback = widget.opportunity.deadlineLabel.trim();
    return fallback.isEmpty
        ? null
        : LocalizedDisplay.dateText(context, fallback);
  }

  String get _primaryCompensationLabel =>
      _effectiveType == OpportunityType.sponsoring
      ? AppLocalizations.of(context)!.uiFunding
      : AppLocalizations.of(context)!.studentSalary;

  String get _compensationNoteTitle =>
      _effectiveType == OpportunityType.sponsoring
      ? AppLocalizations.of(context)!.studentFundingNote
      : AppLocalizations.of(context)!.studentCompensationNote;

  String? get _salaryLabel {
    final label = OpportunityMetadata.formatSalaryRange(
      salaryMin: widget.opportunity.salaryMin,
      salaryMax: widget.opportunity.salaryMax,
      salaryCurrency: widget.opportunity.salaryCurrency,
      salaryPeriod: widget.opportunity.salaryPeriod,
    );
    return label == null ? null : LocalizedDisplay.compensation(context, label);
  }

  String? get _fundingLabel {
    final label = widget.opportunity.fundingLabel();
    return label == null
        ? null
        : LocalizedDisplay.metadataLabel(context, label);
  }

  String? get _primaryCompensationValue =>
      _effectiveType == OpportunityType.sponsoring
      ? _fundingLabel
      : _salaryLabel;

  String? get _compensationNote {
    final note = OpportunityMetadata.sanitizeText(
      _effectiveType == OpportunityType.sponsoring
          ? widget.opportunity.fundingNote
          : widget.opportunity.compensationText,
    );
    if (note == null) {
      return null;
    }

    final primaryValue = _primaryCompensationValue;
    if (primaryValue != null &&
        note.trim().toLowerCase() == primaryValue.trim().toLowerCase()) {
      return null;
    }

    return note;
  }

  String? get _durationLabel {
    final normalizedDuration = OpportunityMetadata.normalizeDuration(
      widget.opportunity.duration,
    );
    if (normalizedDuration != null) {
      return LocalizedDisplay.duration(context, normalizedDuration);
    }
    final fallback = OpportunityMetadata.normalizeDuration(
      _readText(<String>['programDuration', 'internshipDuration', 'timeline']),
    );
    return fallback == null
        ? null
        : LocalizedDisplay.duration(context, fallback);
  }

  String? get _employmentTypeLabel {
    final label = OpportunityMetadata.formatEmploymentType(
      widget.opportunity.employmentType,
    );
    return label == null
        ? null
        : LocalizedDisplay.metadataLabel(context, label);
  }

  String? get _workModeLabel {
    final label = OpportunityMetadata.formatWorkMode(
      widget.opportunity.workMode,
    );
    return label == null
        ? null
        : LocalizedDisplay.metadataLabel(context, label);
  }

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

    final titleCased = normalized
        .split(' ')
        .where((part) => part.isNotEmpty)
        .map(
          (part) =>
              '${part[0].toUpperCase()}${part.substring(1).toLowerCase()}',
        )
        .join(' ');
    return LocalizedDisplay.metadataLabel(context, titleCased);
  }

  String get _overviewTitle => _effectiveType == OpportunityType.sponsoring
      ? AppLocalizations.of(context)!.studentProgramOverview
      : AppLocalizations.of(context)!.uiOverview;

  String get _requirementsTitle => _effectiveType == OpportunityType.sponsoring
      ? AppLocalizations.of(context)!.eligibilityLabel
      : AppLocalizations.of(context)!.requirementsLabel;

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
    return date == null
        ? null
        : LocalizedDisplay.shortDate(context, date, includeYear: true);
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
    final l10n = AppLocalizations.of(context)!;
    final displayTitle = DisplayText.opportunityTitle(
      widget.opportunity.title,
      fallback: l10n.notifTypeOpportunity,
    );
    final displayDescription = widget.opportunity.description.trim();
    final postedLanguage = ContentLanguage.normalizeCode(
      widget.opportunity.originalLanguage,
    );

    final savedProvider = context.watch<SavedOpportunityProvider>();
    final applicationProvider = context.watch<ApplicationProvider>();
    final submittedApplication = _submittedApplication(applicationProvider);
    final acceptedApplication = _acceptedApplication(applicationProvider);
    final isAcceptedApplication = acceptedApplication != null;
    final hasWithdrawalHistory =
        submittedApplication != null &&
        (ApplicationStatus.parse(submittedApplication.status) ==
                ApplicationStatus.withdrawn ||
            submittedApplication.hadWithdrawnBefore);
    final isAdminAcceptedOpportunity =
        isAcceptedApplication && widget.opportunity.isAdminPosted;
    final canOpenCompanyChat =
        isAcceptedApplication && !widget.opportunity.isAdminPosted;
    final isSaved = _existingSavedOpportunity(savedProvider) != null;
    final applyBar = FutureBuilder<ApplicationEligibilityStatus>(
      future: _eligibilityFuture,
      builder: (context, snapshot) {
        final status = snapshot.data ?? ApplicationEligibilityStatus.available;
        final canApply = status == ApplicationEligibilityStatus.available;

        return SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsetsDirectional.fromSTEB(16, 8, 16, 16),
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
                  if (canOpenCompanyChat) ...<Widget>[
                    _ApprovedChatCue(theme: _theme, companyName: _companyName),
                    const SizedBox(height: 10),
                    AppPrimaryButton(
                      theme: _theme,
                      label: _isChatOpening
                          ? AppLocalizations.of(context)!.studentOpeningChat
                          : AppLocalizations.of(
                              context,
                            )!.studentChatWithCompany,
                      icon: Icons.chat_bubble_outline_rounded,
                      isBusy: _isChatOpening,
                      onPressed: _openCompanyChat,
                    ),
                  ] else
                    AppPrimaryButton(
                      theme: _theme,
                      label: _isApplying
                          ? AppLocalizations.of(
                              context,
                            )!.studentApplyingEllipsis
                          : _buttonLabelForStatus(status, applicationProvider),
                      icon: canApply
                          ? (widget.opportunity.isEarlyAccessActive
                                ? Icons.bolt_rounded
                                : Icons.send_rounded)
                          : Icons.info_outline_rounded,
                      isBusy: _isApplying,
                      onPressed: canApply
                          ? _apply
                          : () => _refreshEligibility(),
                    ),
                  const SizedBox(height: 10),
                  Row(
                    children: <Widget>[
                      Expanded(
                        child: AppSecondaryButton(
                          theme: _theme,
                          label: isSaved
                              ? AppLocalizations.of(context)!.uiSaved
                              : AppLocalizations.of(context)!.studentSave,
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
                          label: AppLocalizations.of(context)!.studentPublisher,
                          icon: Icons.account_circle_outlined,
                          onPressed: _openPublisherProfile,
                        ),
                      ),
                    ],
                  ),
                  if (_appliedStatusFor(applicationProvider) ==
                      ApplicationStatus.pending) ...[
                    const SizedBox(height: 6),
                    SizedBox(
                      width: double.infinity,
                      child: TextButton(
                        onPressed: _isWithdrawing ? null : _withdraw,
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 4),
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                        child: AppInlineIconLabel(
                          leading: _isWithdrawing
                              ? SizedBox(
                                  width: 14,
                                  height: 14,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: AppColors.current.danger,
                                  ),
                                )
                              : null,
                          icon: _isWithdrawing ? null : Icons.undo_rounded,
                          iconSize: 16,
                          iconColor: AppColors.current.danger,
                          gap: 7,
                          label: Text(
                            _isWithdrawing
                                ? AppLocalizations.of(
                                    context,
                                  )!.studentWithdrawing
                                : AppLocalizations.of(
                                    context,
                                  )!.studentWithdrawApplicationAction,
                            style: TextStyle(
                              fontSize: 12,
                              color: AppColors.current.danger,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
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
          OpportunityType.label(_effectiveType, AppLocalizations.of(context)!),
          style: _theme.section(size: 18, weight: FontWeight.w700),
        ),
        actions: <Widget>[
          IconButton(
            tooltip: isSaved
                ? AppLocalizations.of(context)!.studentUnsaveOpportunityTooltip
                : AppLocalizations.of(context)!.studentSaveOpportunityTooltip,
            onPressed: _toggleSavedOpportunity,
            icon: Icon(
              isSaved ? Icons.bookmark_rounded : Icons.bookmark_outline_rounded,
            ),
          ),
          IconButton(
            tooltip: AppLocalizations.of(context)!.uiShareOpportunity,
            onPressed: _shareOpportunity,
            icon: const Icon(Icons.ios_share_rounded),
          ),
          const SizedBox(width: 6),
        ],
      ),
      bottomNavigationBar: applyBar,
      body: ListView(
        padding: EdgeInsetsDirectional.fromSTEB(
          16,
          8,
          16,
          canOpenCompanyChat ? 178 : 132,
        ),
        children: <Widget>[
          // Early access banner shown above the hero card (when applicable)
          if (widget.opportunity.isEarlyAccessActive) ...[
            Padding(
              padding: const EdgeInsets.fromLTRB(0, 0, 0, 12),
              child: EarlyAccessDetailBanner(
                publicVisibleAt: widget.opportunity.publicVisibleAt,
              ),
            ),
          ],
          AppDetailHeroCard(
            theme: _theme,
            icon: OpportunityType.icon(_effectiveType),
            title: displayTitle,
            subtitle: _companyName,
            summary: displayDescription,
            badges: <AppBadgeData>[
              AppBadgeData(
                label: OpportunityType.label(
                  _effectiveType,
                  AppLocalizations.of(context)!,
                ),
                icon: OpportunityType.icon(_effectiveType),
              ),
              if (widget.opportunity.status.trim().isNotEmpty)
                AppBadgeData(
                  label: _displayStatusLabel(
                    widget.opportunity.effectiveStatus(),
                  ),
                ),
              ..._heroTags.map((tag) => AppBadgeData(label: tag)),
            ],
            footer: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                AppMetaRow(
                  theme: _theme,
                  label: AppLocalizations.of(context)!.uiLocation,
                  value: _locationValue,
                  icon: Icons.location_on_outlined,
                ),
                AppMetaRow(
                  theme: _theme,
                  label: AppLocalizations.of(context)!.uiDeadline,
                  value: _deadlineLabel ?? '',
                  icon: Icons.event_outlined,
                ),
                AppMetaRow(
                  theme: _theme,
                  label: AppLocalizations.of(context)!.uiPosted,
                  value: widget.opportunity.createdAt == null
                      ? ''
                      : LocalizedDisplay.shortDate(
                          context,
                          widget.opportunity.createdAt!.toDate(),
                          includeYear: true,
                        ),
                  icon: Icons.schedule_outlined,
                ),
              ],
            ),
          ),
          if (postedLanguage.isNotEmpty) ...<Widget>[
            const SizedBox(height: 10),
            _PostedLanguageBanner(
              theme: _theme,
              languageCode: postedLanguage,
              l10n: l10n,
            ),
          ],
          if (isAdminAcceptedOpportunity) ...<Widget>[
            const SizedBox(height: 16),
            _ApprovedEmailContactNotice(theme: _theme),
          ],
          if (hasWithdrawalHistory) ...<Widget>[
            const SizedBox(height: 16),
            _WithdrawnApplicationNotice(
              theme: _theme,
              isCurrentlyWithdrawn:
                  ApplicationStatus.parse(submittedApplication.status) ==
                  ApplicationStatus.withdrawn,
            ),
          ],
          const SizedBox(height: 16),
          AppInfoTileGrid(
            theme: _theme,
            items: <AppInfoTileData>[
              AppInfoTileData(
                label: AppLocalizations.of(context)!.uiType,
                value: OpportunityType.label(
                  _effectiveType,
                  AppLocalizations.of(context)!,
                ),
                icon: OpportunityType.icon(_effectiveType),
              ),
              AppInfoTileData(
                label: _primaryCompensationLabel,
                value: _primaryCompensationValue ?? '',
                icon: _effectiveType == OpportunityType.sponsoring
                    ? Icons.savings_outlined
                    : Icons.payments_outlined,
                emphasize: _primaryCompensationValue != null,
              ),
              AppInfoTileData(
                label: AppLocalizations.of(context)!.uiLocation,
                value: _locationValue,
                icon: Icons.location_on_outlined,
              ),
              AppInfoTileData(
                label: AppLocalizations.of(context)!.uiDeadline,
                value: _deadlineLabel ?? '',
                icon: Icons.event_available_rounded,
              ),
              AppInfoTileData(
                label: AppLocalizations.of(context)!.uiDuration,
                value: _durationLabel ?? '',
                icon: Icons.schedule_outlined,
              ),
              AppInfoTileData(
                label: AppLocalizations.of(context)!.uiWorkMode,
                value: _workModeLabel ?? '',
                icon: Icons.lan_outlined,
              ),
              AppInfoTileData(
                label: AppLocalizations.of(context)!.uiEmploymentType,
                value: _employmentTypeLabel ?? '',
                icon: Icons.badge_outlined,
              ),
              AppInfoTileData(
                label: AppLocalizations.of(context)!.uiExperienceLevel,
                value: _experienceLevelLabel ?? '',
                icon: Icons.trending_up_rounded,
              ),
              AppInfoTileData(
                label: AppLocalizations.of(context)!.uiStartDate,
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
              DisplayText.capitalizeDisplayValue(displayDescription),
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
                  ? AppLocalizations.of(context)!.studentProgramDetails
                  : AppLocalizations.of(context)!.studentResponsibilities,
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
              title: AppLocalizations.of(context)!.uiBenefits,
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
              title: AppLocalizations.of(context)!.uiApplicationProcess,
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
              title: AppLocalizations.of(context)!.uiSkillsNeeded,
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
            title: AppLocalizations.of(context)!.uiAdditionalInformation,
            icon: Icons.info_outline_rounded,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                AppMetaRow(
                  theme: _theme,
                  label: AppLocalizations.of(context)!.uiCompany,
                  value: _companyName,
                ),
                AppMetaRow(
                  theme: _theme,
                  label: AppLocalizations.of(context)!.uiWorkMode,
                  value: _workModeLabel ?? '',
                ),
                AppMetaRow(
                  theme: _theme,
                  label: AppLocalizations.of(context)!.uiEmploymentType,
                  value: _employmentTypeLabel ?? '',
                ),
                AppMetaRow(
                  theme: _theme,
                  label: AppLocalizations.of(context)!.uiExperienceLevel,
                  value: _experienceLevelLabel ?? '',
                ),
                AppMetaRow(
                  theme: _theme,
                  label: AppLocalizations.of(context)!.uiPaidStatus,
                  value: LocalizedDisplay.metadataLabel(
                    context,
                    OpportunityMetadata.formatPaidLabel(
                          widget.opportunity.isPaid,
                        ) ??
                        '',
                  ),
                ),
                AppMetaRow(
                  theme: _theme,
                  label: _primaryCompensationLabel,
                  value: _primaryCompensationValue ?? '',
                ),
                AppMetaRow(
                  theme: _theme,
                  label: AppLocalizations.of(context)!.uiDuration,
                  value: _durationLabel ?? '',
                ),
                AppMetaRow(
                  theme: _theme,
                  label: AppLocalizations.of(context)!.uiStartDate,
                  value: _startDateLabel ?? '',
                ),
                AppMetaRow(
                  theme: _theme,
                  label: AppLocalizations.of(context)!.uiContact,
                  value: _contactInfo ?? '',
                ),
                AppMetaRow(
                  theme: _theme,
                  label: AppLocalizations.of(context)!.uiExternalLink,
                  value: _externalLink ?? '',
                ),
                if (_readList(<String>['attachments', 'documents']).isNotEmpty)
                  AppMetaRow(
                    theme: _theme,
                    label: AppLocalizations.of(context)!.uiAttachments,
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
              title: AppLocalizations.of(context)!.uiTags,
              icon: Icons.local_offer_outlined,
              child: _OpportunityChipWrap(theme: _theme, items: _explicitTags),
            ),
          ],
          if (_externalLink != null &&
              _externalLink!.trim().isNotEmpty) ...<Widget>[
            const SizedBox(height: 16),
            AppDetailSection(
              theme: _theme,
              title: AppLocalizations.of(context)!.uiExternalApplication,
              icon: Icons.open_in_new_rounded,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  AppMetaRow(
                    theme: _theme,
                    label: AppLocalizations.of(context)!.uiLink,
                    value: _externalLink!,
                    icon: Icons.link_rounded,
                  ),
                  const SizedBox(height: 8),
                  AppPrimaryButton(
                    theme: _theme,
                    label: AppLocalizations.of(context)!.uiOpenLink,
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

class _ApprovedEmailContactNotice extends StatelessWidget {
  final AppContentTheme theme;

  const _ApprovedEmailContactNotice({required this.theme});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: theme.success.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: theme.success.withValues(alpha: 0.16)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: theme.success.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              Icons.mark_email_read_outlined,
              size: 18,
              color: theme.success,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  AppLocalizations.of(context)!.uiApplicationApprovedB0Cb,
                  style: theme.label(
                    size: 12.8,
                    color: theme.success,
                    weight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  AppLocalizations.of(
                    context,
                  )!.uiTheCompanyWillContactYouByEmailSoon,
                  style: theme.body(
                    size: 12.2,
                    color: theme.textSecondary,
                    weight: FontWeight.w500,
                    height: 1.4,
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

class _WithdrawnApplicationNotice extends StatelessWidget {
  final AppContentTheme theme;
  final bool isCurrentlyWithdrawn;

  const _WithdrawnApplicationNotice({
    required this.theme,
    required this.isCurrentlyWithdrawn,
  });

  @override
  Widget build(BuildContext context) {
    final accent = AppColors.current.warning;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: accent.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: accent.withValues(alpha: 0.18)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: accent.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: AppDirectionalIcon(
              Icons.undo_rounded,
              size: 18,
              color: accent,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  AppLocalizations.of(
                    context,
                  )!.studentApplicationWithdrawnBefore,
                  style: theme.label(
                    size: 12.8,
                    color: accent,
                    weight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  isCurrentlyWithdrawn
                      ? AppLocalizations.of(
                          context,
                        )!.studentWithdrawnCurrentMessage
                      : AppLocalizations.of(
                          context,
                        )!.studentWithdrawnPreviousMessage,
                  style: theme.body(
                    size: 12.2,
                    color: theme.textSecondary,
                    weight: FontWeight.w500,
                    height: 1.4,
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

class _ApprovedChatCue extends StatelessWidget {
  final AppContentTheme theme;
  final String companyName;

  const _ApprovedChatCue({required this.theme, required this.companyName});

  @override
  Widget build(BuildContext context) {
    final trimmedCompany = companyName.trim();
    final companyLabel = trimmedCompany.isEmpty
        ? AppLocalizations.of(context)!.studentTheCompany
        : trimmedCompany;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: theme.success.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: theme.success.withValues(alpha: 0.16)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: theme.success.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(Icons.verified_rounded, size: 15, color: theme.success),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Text(
                  AppLocalizations.of(context)!.uiApplicationApprovedB0Cb,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.label(
                    size: 12.2,
                    color: theme.success,
                    weight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  AppLocalizations.of(
                    context,
                  )!.studentCanMessageCompany(companyLabel),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: theme.body(
                    size: 11.6,
                    color: theme.textSecondary,
                    weight: FontWeight.w500,
                    height: 1.35,
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
                  DisplayText.capitalizeDisplayValue(title),
                  style: theme.label(
                    size: 11.3,
                    color: theme.accentDark,
                    weight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  DisplayText.capitalizeDisplayValue(trimmedNote),
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
                        DisplayText.capitalizeDisplayValue(item),
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

    return Text(
      DisplayText.capitalizeDisplayValue(text),
      style: theme.body(color: theme.textPrimary),
    );
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

class _PostedLanguageBanner extends StatelessWidget {
  final AppContentTheme theme;
  final String languageCode;
  final AppLocalizations l10n;

  const _PostedLanguageBanner({
    required this.theme,
    required this.languageCode,
    required this.l10n,
  });

  @override
  Widget build(BuildContext context) {
    final accent = theme.accent;
    final languageName = ContentLanguage.localizedName(context, languageCode);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: accent.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: accent.withValues(alpha: 0.18)),
      ),
      child: Row(
        children: [
          Icon(Icons.language_rounded, size: 15, color: accent),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              l10n.studentOriginalLanguageValue(
                l10n.originalLanguageLabel,
                languageName,
              ),
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: accent,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
