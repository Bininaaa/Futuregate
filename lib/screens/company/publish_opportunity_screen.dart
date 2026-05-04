import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../l10n/generated/app_localizations.dart';
import '../../providers/auth_provider.dart';
import '../../providers/company_provider.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_typography.dart';
import '../../theme/locale_controller.dart';
import '../../utils/content_language.dart';
import '../../utils/company_dashboard_palette.dart';
import '../../utils/opportunity_metadata.dart';
import '../../utils/opportunity_type.dart';
import '../../widgets/app_shell_background.dart';
import '../../widgets/opportunity_type_selector.dart';
import '../../widgets/shared/app_content_system.dart';
import '../../widgets/shared/app_feedback.dart';
import '../../widgets/shared/app_loading.dart';

class PublishOpportunityScreen extends StatefulWidget {
  final String? opportunityId;

  const PublishOpportunityScreen({super.key, this.opportunityId});

  @override
  State<PublishOpportunityScreen> createState() =>
      _PublishOpportunityScreenState();
}

class _PublishOpportunityScreenState extends State<PublishOpportunityScreen> {
  static Color get primaryDark => CompanyDashboardPalette.primaryDark;

  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _locationController = TextEditingController();
  final _deadlineController = TextEditingController();
  final _salaryMinController = TextEditingController();
  final _salaryMaxController = TextEditingController();
  final _compensationTextController = TextEditingController();
  final _fundingAmountController = TextEditingController();
  final _fundingNoteController = TextEditingController();
  final _durationController = TextEditingController();
  final _requirementsListController = AppEditableListController();
  List<String> _requirementItems = <String>[];

  String _selectedType = OpportunityType.job;
  String _selectedStatus = 'open';
  String? _selectedSalaryCurrency =
      OpportunityMetadata.supportedCurrencies.first;
  String? _selectedFundingCurrency =
      OpportunityMetadata.supportedCurrencies.first;
  String? _selectedSalaryPeriod;
  String? _selectedEmploymentType;
  String? _selectedWorkMode;
  bool? _isPaid;
  DateTime? _applicationDeadline;
  String _originalLanguage = 'fr';

  bool _isLoading = false;
  bool _isSubmitting = false;
  bool _isEditMode = false;
  bool _requestEarlyAccess = false;
  String _currentEarlyAccessStatus = 'none';

  Color get _typeColor => OpportunityType.color(_selectedType);
  bool get _usesStructuredFields =>
      OpportunityMetadata.usesStructuredFields(_selectedType);
  bool get _isInternship =>
      OpportunityType.parse(_selectedType) == OpportunityType.internship;
  bool get _isSponsoring =>
      OpportunityType.parse(_selectedType) == OpportunityType.sponsoring;
  AppLocalizations get _l10n => AppLocalizations.of(context)!;

  AppContentTheme get _theme => AppContentTheme.futureGate(
    accent: CompanyDashboardPalette.primary,
    accentDark: CompanyDashboardPalette.primaryDark,
    accentSoft: CompanyDashboardPalette.primarySoft,
    secondary: CompanyDashboardPalette.secondary,
    heroGradient: LinearGradient(
      colors: <Color>[
        CompanyDashboardPalette.primaryDark,
        CompanyDashboardPalette.primary,
        CompanyDashboardPalette.secondary,
      ],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    ),
  );

  @override
  void initState() {
    super.initState();
    _originalLanguage = _preferredPostingLanguage();
    if (widget.opportunityId != null) {
      _isEditMode = true;
      _loadOpportunity();
    }
  }

  String _preferredPostingLanguage() {
    final auth = context.read<AuthProvider>().userModel;
    final preferred = ContentLanguage.normalizeCode(
      auth?.preferredPostingLanguage,
    );
    if (preferred.isNotEmpty) {
      return preferred;
    }

    return ContentLanguage.normalizeCode(
      LocaleController.activeLanguageCode,
      fallback: 'fr',
    );
  }

  Future<void> _loadOpportunity() async {
    setState(() => _isLoading = true);

    final provider = context.read<CompanyProvider>();
    final opp = await provider.getOpportunityById(widget.opportunityId!);

    if (opp != null) {
      _titleController.text = opp.title;
      _descriptionController.text = opp.description;
      _locationController.text = opp.location;
      _requirementItems = opp.requirementItems.isNotEmpty
          ? List<String>.from(opp.requirementItems)
          : OpportunityMetadata.extractRequirementItems(
              opp.rawData,
              fallbackText: opp.requirements,
            );
      _selectedType = OpportunityType.parse(opp.type);
      _selectedStatus = opp.effectiveStatus() == 'closed' ? 'closed' : 'open';

      final existingDeadline =
          opp.applicationDeadline ??
          OpportunityMetadata.parseDateTimeLike(opp.deadline);
      if (existingDeadline != null) {
        _applicationDeadline = DateTime(
          existingDeadline.year,
          existingDeadline.month,
          existingDeadline.day,
        );
        _deadlineController.text = OpportunityMetadata.formatDateForStorage(
          existingDeadline,
        );
      } else {
        _deadlineController.text = opp.deadline;
      }

      _salaryMinController.text = _formatNumberForInput(opp.salaryMin);
      _salaryMaxController.text = _formatNumberForInput(opp.salaryMax);
      _compensationTextController.text = opp.compensationText ?? '';
      _fundingAmountController.text = _formatNumberForInput(
        opp.fundingAmount ?? (_isSponsoring ? opp.salaryMin : null),
      );
      _fundingNoteController.text =
          opp.fundingNote ?? (_isSponsoring ? opp.compensationText ?? '' : '');
      _durationController.text = opp.duration ?? '';

      _selectedSalaryCurrency =
          opp.salaryCurrency ??
          _selectedSalaryCurrency ??
          OpportunityMetadata.supportedCurrencies.first;
      _selectedSalaryPeriod = opp.salaryPeriod;
      _selectedFundingCurrency =
          opp.fundingCurrency ??
          opp.salaryCurrency ??
          _selectedFundingCurrency ??
          OpportunityMetadata.supportedCurrencies.first;
      _selectedEmploymentType = opp.employmentType;
      _selectedWorkMode = opp.workMode;
      _isPaid = opp.isPaid;
      _requestEarlyAccess = opp.earlyAccessRequested;
      _currentEarlyAccessStatus = opp.earlyAccessStatus;
      _originalLanguage = ContentLanguage.normalizeCode(
        opp.originalLanguage,
        fallback: _preferredPostingLanguage(),
      );

      _applyTypeDefaults(_selectedType);
    }

    if (!mounted) {
      return;
    }

    setState(() => _isLoading = false);
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _locationController.dispose();
    _deadlineController.dispose();
    _salaryMinController.dispose();
    _salaryMaxController.dispose();
    _compensationTextController.dispose();
    _fundingAmountController.dispose();
    _fundingNoteController.dispose();
    _durationController.dispose();
    _requirementsListController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AppShellBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          title: Text(
            _isEditMode
                ? _l10n.editOpportunityTitle
                : _l10n.publishOpportunityTitle,
            style: AppTypography.product(
              fontWeight: FontWeight.w700,
              color: primaryDark,
            ),
          ),
          backgroundColor: Colors.transparent,
          surfaceTintColor: Colors.transparent,
          scrolledUnderElevation: 0,
          elevation: 0,
          iconTheme: IconThemeData(color: primaryDark),
        ),
        bottomNavigationBar: _isLoading
            ? null
            : SafeArea(
                top: false,
                child: Container(
                  padding: const EdgeInsets.fromLTRB(20, 14, 20, 18),
                  decoration: BoxDecoration(
                    color: CompanyDashboardPalette.surface,
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.current.shadow.withValues(
                          alpha: AppColors.isDark ? 0.24 : 0.05,
                        ),
                        blurRadius: 20,
                        offset: const Offset(0, -6),
                      ),
                    ],
                  ),
                  child: AppPrimaryButton(
                    theme: _theme,
                    label: _isEditMode
                        ? _l10n.saveOpportunityChangesLabel
                        : _l10n.publishContentType(
                            OpportunityType.label(_selectedType, _l10n),
                          ),
                    onPressed: _isSubmitting ? null : _submit,
                    isBusy: _isSubmitting,
                  ),
                ),
              ),
        body: _isLoading
            ? const AppLoadingView(density: AppLoadingDensity.compact)
            : SafeArea(
                child: Form(
                  key: _formKey,
                  autovalidateMode: AutovalidateMode.onUserInteraction,
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(20, 10, 20, 30),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildHeroCard(),
                        const SizedBox(height: 12),
                        _buildSectionCard(
                          title: _l10n.basicInformationTitle,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildField(
                                controller: _titleController,
                                label: _l10n.opportunityTitleLabel,
                                hint: _titleHintForType(_l10n),
                                validator: _validateTitle,
                              ),
                              const SizedBox(height: 10),
                              _buildDropdownField<String>(
                                value: _originalLanguage,
                                label: _l10n.originalLanguageFieldLabel,
                                hint: _l10n.originalLanguageFieldLabel,
                                items: [
                                  DropdownMenuItem(
                                    value: ContentLanguage.french,
                                    child: Text(_l10n.languageFrench),
                                  ),
                                  DropdownMenuItem(
                                    value: ContentLanguage.english,
                                    child: Text(_l10n.languageEnglish),
                                  ),
                                  DropdownMenuItem(
                                    value: ContentLanguage.arabic,
                                    child: Text(_l10n.languageArabic),
                                  ),
                                ],
                                onChanged: (value) {
                                  if (value == null) return;
                                  setState(() => _originalLanguage = value);
                                },
                              ),
                              const SizedBox(height: 14),
                              _buildSectionLabel(_l10n.opportunityTypeLabel),
                              const SizedBox(height: 10),
                              OpportunityTypeSelector(
                                selected: _selectedType,
                                onChanged: (value) {
                                  if (_selectedType == value) {
                                    return;
                                  }
                                  setState(() {
                                    _selectedType = value;
                                    _applyTypeDefaults(value);
                                  });
                                },
                              ),
                              const SizedBox(height: 14),
                              _buildEarlyAccessToggle(),
                              const SizedBox(height: 14),
                              _buildSectionLabel(_l10n.publishingStatusLabel),
                              const SizedBox(height: 10),
                              Row(
                                children: [
                                  Expanded(
                                    child: _buildStatusChip(
                                      label: _l10n.openStatusLabel,
                                      value: 'open',
                                      subtitle: _l10n.openStatusSubtitle,
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: _buildStatusChip(
                                      label: _l10n.closedStatusLabel,
                                      value: 'closed',
                                      subtitle: _l10n.closedStatusSubtitle,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 14),
                              _buildField(
                                controller: _locationController,
                                label: _l10n.locationLabel,
                                hint: _locationHintForType(_l10n),
                                validator: _validateLocation,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 12),
                        _buildSectionCard(
                          title: _l10n.descriptionSectionTitle,
                          child: _buildField(
                            controller: _descriptionController,
                            label: OpportunityType.descriptionLabel(
                              _selectedType,
                              _l10n,
                            ),
                            hint: OpportunityType.descriptionHint(
                              _selectedType,
                              _l10n,
                            ),
                            maxLines: 6,
                            minLength: 60,
                            helperText:
                                _l10n.publishOpportunityDescriptionHelperText,
                            validator: _validateDescription,
                          ),
                        ),
                        const SizedBox(height: 12),
                        _buildSectionCard(
                          title: OpportunityType.requirementsLabel(
                            _selectedType,
                            _l10n,
                          ),
                          subtitle: _requirementsSectionSubtitle(),
                          child: AppEditableListField(
                            theme: _theme,
                            label: '',
                            hint: _isSponsoring
                                ? _l10n.typeOneEligibilityHint
                                : _l10n.typeOneRequirementHint,
                            values: _requirementItems,
                            onChanged: (items) =>
                                setState(() => _requirementItems = items),
                            listController: _requirementsListController,
                            validator: _validateRequirementItems,
                            splitOnCommas: false,
                            emptyText: '',
                          ),
                        ),
                        const SizedBox(height: 12),
                        _buildStructuredOpportunityCard(),
                      ],
                    ),
                  ),
                ),
              ),
      ),
    );
  }

  Widget _buildHeroCard() {
    final statusColor = _selectedStatus == 'open'
        ? CompanyDashboardPalette.success
        : CompanyDashboardPalette.textSecondary;

    return AppFormHeaderCard(
      theme: _theme,
      icon: OpportunityType.icon(_selectedType),
      title: OpportunityType.headline(_selectedType, _l10n),
      subtitle: _isEditMode
          ? _l10n.uiUpdateTheFieldsBelowAndSave
          : _l10n.uiFillInTheFieldsBelowThenPublish,
      badges: <AppBadgeData>[
        AppBadgeData(
          label: OpportunityType.label(_selectedType, _l10n),
          icon: OpportunityType.icon(_selectedType),
          color: _typeColor,
        ),
        AppBadgeData(
          label: _selectedStatus == 'open'
              ? _l10n.openStatusLabel
              : _l10n.closedStatusLabel,
          icon: _selectedStatus == 'open'
              ? Icons.visibility_outlined
              : Icons.lock_outline_rounded,
          color: statusColor,
        ),
      ],
    );
  }

  Widget _buildStructuredOpportunityCard() {
    return _buildSectionCard(
      title: _usesStructuredFields || _isSponsoring
          ? _l10n.logisticsTitle
          : _l10n.publishLabel,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildField(
            controller: _deadlineController,
            label: _l10n.applicationDeadlineLabel,
            hint: _l10n.selectClosingDateHint,
            validator: _validateDeadline,
            onTap: _pickDate,
            readOnly: true,
            suffixIcon: const Icon(Icons.calendar_today),
          ),
          if (_isSponsoring) ...[
            const SizedBox(height: 14),
            _buildSectionLabel(_l10n.companyFundingSectionTitle),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: _buildField(
                    controller: _fundingAmountController,
                    label: _l10n.fundingAmountLabel,
                    hint: _l10n.fundingAmountLabel,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    validator: _validateFundingAmount,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _buildDropdownField<String>(
                    value: _selectedFundingCurrency,
                    label: _l10n.fundingCurrencyLabel,
                    hint: _l10n.uiCurrency,
                    items: OpportunityMetadata.supportedCurrencies
                        .map(
                          (currency) => DropdownMenuItem<String>(
                            value: currency,
                            child: Text(currency),
                          ),
                        )
                        .toList(),
                    onChanged: (value) {
                      setState(() => _selectedFundingCurrency = value);
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _buildField(
              controller: _fundingNoteController,
              label: _l10n.fundingNoteLabel,
              hint: _l10n.optionalSupportDetailsShownToStudents,
              maxLines: 2,
              validator: _validateFundingNote,
            ),
          ],
          if (_usesStructuredFields) ...[
            const SizedBox(height: 14),
            _buildSectionLabel(
              _isInternship
                  ? _l10n.internshipCompensationSectionTitle
                  : _l10n.compensationAndFormatSectionTitle,
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: _buildField(
                    controller: _salaryMinController,
                    label: _l10n.salaryMinimumLabel,
                    hint: _l10n.salaryMinimumLabel,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    validator: _validateSalaryMin,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _buildField(
                    controller: _salaryMaxController,
                    label: _l10n.salaryMaximumLabel,
                    hint: _l10n.salaryMaximumLabel,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    validator: _validateSalaryMax,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildDropdownField<String>(
                    value: _selectedSalaryCurrency,
                    label: _l10n.uiCurrency,
                    hint: _l10n.uiCurrency,
                    items: OpportunityMetadata.supportedCurrencies
                        .map(
                          (currency) => DropdownMenuItem<String>(
                            value: currency,
                            child: Text(currency),
                          ),
                        )
                        .toList(),
                    onChanged: (value) {
                      setState(() => _selectedSalaryCurrency = value);
                    },
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _buildDropdownField<String>(
                    value: _selectedSalaryPeriod,
                    label: _l10n.salaryPeriodLabel,
                    hint: _l10n.salaryPeriodLabel,
                    items: OpportunityMetadata.salaryPeriods
                        .map(
                          (period) => DropdownMenuItem<String>(
                            value: period,
                            child: Text(_titleCaseLabel(period)),
                          ),
                        )
                        .toList(),
                    onChanged: (value) {
                      setState(() => _selectedSalaryPeriod = value);
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildDropdownField<String>(
                    value: _selectedEmploymentType,
                    label: _l10n.employmentTypeLabel,
                    hint: _l10n.employmentTypeLabel,
                    items: _employmentTypeOptions
                        .map(
                          (type) => DropdownMenuItem<String>(
                            value: type,
                            child: Text(
                              _employmentTypeLabel(
                                type,
                                AppLocalizations.of(context)!,
                              ),
                            ),
                          ),
                        )
                        .toList(),
                    onChanged: (value) {
                      setState(() => _selectedEmploymentType = value);
                    },
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _buildDropdownField<String>(
                    value: _selectedWorkMode,
                    label: _l10n.workModeLabel,
                    hint: _l10n.workModeLabel,
                    items: OpportunityMetadata.workModes
                        .map(
                          (mode) => DropdownMenuItem<String>(
                            value: mode,
                            child: Text(
                              OpportunityMetadata.formatWorkMode(mode) ??
                                  _titleCaseLabel(mode),
                            ),
                          ),
                        )
                        .toList(),
                    onChanged: (value) {
                      setState(() => _selectedWorkMode = value);
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _buildDropdownField<bool>(
              value: _isPaid,
              label: _l10n.paidStatusLabel,
              hint: _l10n.paidStatusLabel,
              items: [
                DropdownMenuItem<bool>(
                  value: true,
                  child: Text(_l10n.paidLabel),
                ),
                DropdownMenuItem<bool>(
                  value: false,
                  child: Text(_l10n.unpaidLabel),
                ),
              ],
              onChanged: (value) {
                setState(() => _isPaid = value);
              },
            ),
            if (_isInternship) ...[
              const SizedBox(height: 12),
              _buildField(
                controller: _durationController,
                label: _l10n.durationLabel,
                hint: _l10n.durationExampleHint,
                validator: _validateDuration,
              ),
            ],
            const SizedBox(height: 12),
            _buildField(
              controller: _compensationTextController,
              label: _l10n.compensationNoteLabel,
              hint: _l10n.optionalCompensationNoteForDetailScreens,
              maxLines: 2,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSectionCard({
    required String title,
    String? subtitle,
    required Widget child,
  }) {
    return AppFormSectionCard(
      theme: _theme,
      title: title,
      subtitle: subtitle,
      child: child,
    );
  }

  Widget _buildSectionLabel(String text) {
    return Text(
      text,
      style: AppTypography.product(
        fontSize: 14,
        fontWeight: FontWeight.w700,
        color: primaryDark,
      ),
    );
  }

  Widget _buildField({
    required TextEditingController controller,
    required String label,
    required String hint,
    int maxLines = 1,
    String? Function(String?)? validator,
    VoidCallback? onTap,
    bool readOnly = false,
    Widget? suffixIcon,
    TextInputType? keyboardType,
    int? minLength,
    String? helperText,
  }) {
    return AppFormField(
      theme: _theme,
      controller: controller,
      label: label,
      hint: hint,
      maxLines: maxLines,
      validator: validator,
      onTap: onTap,
      readOnly: readOnly,
      keyboardType: keyboardType,
      suffixIcon: suffixIcon,
      minLength: minLength,
      helperText: helperText,
    );
  }

  Widget _buildDropdownField<T>({
    required T? value,
    required String label,
    required String hint,
    required List<DropdownMenuItem<T>> items,
    required ValueChanged<T?> onChanged,
  }) {
    return AppFormDropdownField<T>(
      theme: _theme,
      value: value,
      label: label,
      hint: hint,
      items: items,
      onChanged: onChanged,
    );
  }

  Widget _buildStatusChip({
    required String label,
    required String value,
    required String subtitle,
  }) {
    final isSelected = _selectedStatus == value;
    final chipColor = value == 'open'
        ? CompanyDashboardPalette.success
        : CompanyDashboardPalette.textSecondary;

    return AppChoiceCard(
      theme: _theme,
      label: label,
      subtitle: subtitle,
      selected: isSelected,
      icon: value == 'open'
          ? Icons.visibility_outlined
          : Icons.lock_outline_rounded,
      color: chipColor,
      onTap: () => setState(() => _selectedStatus = value),
    );
  }

  String _titleHintForType(AppLocalizations l10n) {
    return switch (OpportunityType.parse(_selectedType)) {
      OpportunityType.internship => l10n.opportunityTitleHintInternship,
      OpportunityType.sponsoring => l10n.opportunityTitleHintSponsoring,
      _ => l10n.opportunityTitleHintJob,
    };
  }

  String _locationHintForType(AppLocalizations l10n) {
    return switch (OpportunityType.parse(_selectedType)) {
      OpportunityType.sponsoring => l10n.opportunityLocationHintSponsoring,
      _ => l10n.opportunityLocationHintDefault,
    };
  }

  String? _validateTitle(String? value) {
    final text = value?.trim() ?? '';
    if (text.isEmpty) {
      return _l10n.validationTitleRequired;
    }
    if (text.length < 4) {
      return _l10n.validationUseAtLeastFourCharacters;
    }
    return null;
  }

  String? _validateDescription(String? value) {
    final text = value?.trim() ?? '';
    if (text.isEmpty) {
      return _l10n.validationDescriptionRequired;
    }
    if (text.length < 60) {
      return _l10n.validationAddMoreDetail;
    }
    return null;
  }

  String? _validateLocation(String? value) {
    final text = value?.trim() ?? '';
    if (text.isEmpty) {
      return _l10n.validationLocationRequired;
    }
    return null;
  }

  String? _validateRequirementItems(List<String> items) {
    if (items.where((item) => item.trim().isNotEmpty).isEmpty) {
      return _selectedType == OpportunityType.sponsoring
          ? _l10n.validationEligibilityItemRequired
          : _l10n.validationRequirementItemRequired;
    }
    return null;
  }

  String? _validateDeadline(String? value) {
    final text = value?.trim() ?? '';
    if (text.isEmpty) {
      return _l10n.validationDeadlineRequired;
    }

    final parsed =
        _applicationDeadline ?? OpportunityMetadata.parseDateTimeLike(text);
    if (parsed == null) {
      return _l10n.validationValidDate;
    }

    final today = DateTime.now();
    final normalizedToday = DateTime(today.year, today.month, today.day);
    final normalizedDeadline = DateTime(parsed.year, parsed.month, parsed.day);
    if (normalizedDeadline.isBefore(normalizedToday)) {
      return _l10n.validationDeadlinePast;
    }

    return null;
  }

  String? _validateSalaryMin(String? value) {
    if (!_usesStructuredFields) {
      return null;
    }

    final minValue = _parseOptionalNumber(_salaryMinController.text);
    final maxValue = _parseOptionalNumber(_salaryMaxController.text);

    if ((value ?? '').trim().isNotEmpty && minValue == null) {
      return _l10n.validationEnterValidNumber;
    }

    if (minValue != null && maxValue != null && maxValue < minValue) {
      return _l10n.validationMinCannotExceedMax;
    }

    return null;
  }

  String? _validateSalaryMax(String? value) {
    if (!_usesStructuredFields) {
      return null;
    }

    final minValue = _parseOptionalNumber(_salaryMinController.text);
    final maxValue = _parseOptionalNumber(_salaryMaxController.text);

    if ((value ?? '').trim().isNotEmpty && maxValue == null) {
      return _l10n.validationEnterValidNumber;
    }

    if (minValue != null && maxValue != null && maxValue < minValue) {
      return _l10n.validationMaxAtLeastMin;
    }

    return null;
  }

  String? _validateDuration(String? value) {
    if (!_isInternship) {
      return null;
    }

    final text = value?.trim() ?? '';
    if (text.isEmpty) {
      return null;
    }

    if (text.length < 2) {
      return _l10n.validationAddClearerDuration;
    }

    return null;
  }

  String? _validateFundingAmount(String? value) {
    if (!_isSponsoring) {
      return null;
    }

    final text = value?.trim() ?? '';
    final note = _fundingNoteController.text.trim();
    final parsed = _parseOptionalNumber(text);
    if (text.isEmpty && note.isEmpty) {
      return _l10n.validationFundingAmountOrNote;
    }
    if (text.isNotEmpty && parsed == null) {
      return _l10n.validationValidAmount;
    }
    if (parsed != null && parsed < 0) {
      return _l10n.validationAmountNonNegative;
    }
    return null;
  }

  String? _validateFundingNote(String? value) {
    if (!_isSponsoring) {
      return null;
    }

    final amount = _fundingAmountController.text.trim();
    final note = value?.trim() ?? '';
    if (amount.isEmpty && note.isEmpty) {
      return _l10n.validationFundingNoteOrAmount;
    }
    return null;
  }

  String _requirementsSectionSubtitle() {
    return _isSponsoring
        ? _l10n.eligibilityChecklistHelper
        : _l10n.requirementsChecklistHelper;
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final initialDate =
        _applicationDeadline ??
        OpportunityMetadata.parseDateTimeLike(_deadlineController.text) ??
        now.add(const Duration(days: 30));
    final normalizedFirstDate = DateTime(now.year, now.month, now.day);
    final picked = await showDatePicker(
      context: context,
      initialDate: initialDate.isBefore(normalizedFirstDate)
          ? normalizedFirstDate
          : initialDate,
      firstDate: normalizedFirstDate,
      lastDate: DateTime(2035),
      helpText: _l10n.selectClosingDateHint,
    );
    if (picked != null) {
      final normalized = DateTime(picked.year, picked.month, picked.day);
      setState(() {
        _applicationDeadline = normalized;
        _deadlineController.text = OpportunityMetadata.formatDateForStorage(
          normalized,
        );
      });
    }
  }

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();
    _requirementsListController.commitPendingInput();

    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() => _isSubmitting = true);

    final user = context.read<AuthProvider>().userModel;
    final provider = context.read<CompanyProvider>();

    if (user == null) {
      if (!mounted) {
        return;
      }
      setState(() => _isSubmitting = false);
      context.showAppSnackBar(
        _l10n.signInContinuePublishingMessage,
        title: _l10n.loginRequiredTitle,
        type: AppFeedbackType.warning,
      );
      return;
    }

    final deadlineDate =
        _applicationDeadline ??
        OpportunityMetadata.parseDateTimeLike(_deadlineController.text);
    final structuredData = _buildStructuredPayload();
    final requirementText = _requirementItems.join('\n');
    final submittedForEarlyAccessApproval =
        _requestEarlyAccess && _currentEarlyAccessStatus == 'none';
    final data = {
      'title': _titleController.text.trim(),
      'description': _descriptionController.text.trim(),
      'type': _selectedType,
      'originalLanguage': _originalLanguage,
      'location': _locationController.text.trim(),
      'requirements': requirementText,
      'requirementItems': _requirementItems,
      'deadline': deadlineDate == null
          ? _deadlineController.text.trim()
          : OpportunityMetadata.formatDateForStorage(deadlineDate),
      'applicationDeadline': deadlineDate == null
          ? null
          : OpportunityMetadata.normalizeDateToEndOfDay(deadlineDate),
      'companyId': user.uid,
      'companyName': user.companyName ?? user.fullName,
      'companyLogo': user.logo ?? '',
      'createdBy': user.uid,
      'createdByRole': 'company',
      'status': _selectedStatus,
      ...structuredData,
      // Early access request — company can only set to true; admin controls approval.
      if (submittedForEarlyAccessApproval) 'earlyAccessRequested': true,
      if (submittedForEarlyAccessApproval) 'earlyAccessStatus': 'pending',
    };

    String? error;

    if (_isEditMode) {
      error = await provider.updateOpportunity(widget.opportunityId!, data);
    } else {
      error = await provider.createOpportunity(data);
    }

    if (!mounted) {
      return;
    }

    setState(() => _isSubmitting = false);

    if (error != null) {
      context.showAppSnackBar(
        error,
        title: _isEditMode
            ? _l10n.updateUnavailableTitle
            : _l10n.publishUnavailableTitle,
        type: AppFeedbackType.error,
      );
      return;
    }

    late final String feedbackMessage;
    late final String feedbackTitle;
    late final AppFeedbackType feedbackType;
    late final IconData? feedbackIcon;

    if (submittedForEarlyAccessApproval) {
      feedbackMessage = _l10n.earlyAccessApprovalRequiredMessage;
      feedbackTitle = _l10n.earlyAccessApprovalRequiredTitle;
      feedbackType = AppFeedbackType.info;
      feedbackIcon = Icons.pending_actions_rounded;
    } else {
      feedbackMessage = _isEditMode
          ? _l10n.opportunityUpdatedMessage
          : _l10n.opportunityPublishedMessage;
      feedbackTitle = _isEditMode
          ? _l10n.opportunityUpdatedTitle
          : _l10n.opportunityPublishedTitle;
      feedbackType = _selectedStatus == 'closed'
          ? AppFeedbackType.removed
          : AppFeedbackType.success;
      feedbackIcon = _selectedStatus == 'closed'
          ? Icons.lock_outline_rounded
          : null;
    }

    context.showAppSnackBar(
      feedbackMessage,
      title: feedbackTitle,
      type: feedbackType,
      icon: feedbackIcon,
    );
    Navigator.pop(context);
  }

  Map<String, dynamic> _buildStructuredPayload() {
    if (_isSponsoring) {
      return {
        'salaryMin': null,
        'salaryMax': null,
        'salaryCurrency': null,
        'salaryPeriod': null,
        'compensationText': null,
        'employmentType': null,
        'workMode': null,
        'isPaid': null,
        'duration': null,
        'fundingAmount': _parseOptionalNumber(_fundingAmountController.text),
        'fundingCurrency': _selectedFundingCurrency,
        'fundingNote': OpportunityMetadata.sanitizeText(
          _fundingNoteController.text,
        ),
      };
    }

    if (!_usesStructuredFields) {
      return const {
        'salaryMin': null,
        'salaryMax': null,
        'salaryCurrency': null,
        'salaryPeriod': null,
        'compensationText': null,
        'employmentType': null,
        'workMode': null,
        'isPaid': null,
        'duration': null,
        'fundingAmount': null,
        'fundingCurrency': null,
        'fundingNote': null,
      };
    }

    return {
      'salaryMin': _parseOptionalNumber(_salaryMinController.text),
      'salaryMax': _parseOptionalNumber(_salaryMaxController.text),
      'salaryCurrency': _selectedSalaryCurrency,
      'salaryPeriod': _selectedSalaryPeriod,
      'compensationText': OpportunityMetadata.sanitizeText(
        _compensationTextController.text,
      ),
      'employmentType': _selectedEmploymentType,
      'workMode': _selectedWorkMode,
      'isPaid': _isPaid,
      'duration': _isInternship
          ? OpportunityMetadata.normalizeDuration(_durationController.text)
          : null,
      'fundingAmount': null,
      'fundingCurrency': null,
      'fundingNote': null,
    };
  }

  num? _parseOptionalNumber(String rawValue) {
    return OpportunityMetadata.parseNullableNum(rawValue);
  }

  void _applyTypeDefaults(String type) {
    if (OpportunityType.parse(type) == OpportunityType.sponsoring) {
      _salaryMinController.clear();
      _salaryMaxController.clear();
      _compensationTextController.clear();
      _selectedSalaryPeriod = null;
      _selectedEmploymentType = null;
      _selectedWorkMode = null;
      _isPaid = null;
      _durationController.clear();
      _selectedFundingCurrency ??=
          OpportunityMetadata.supportedCurrencies.first;
      return;
    }

    _fundingAmountController.clear();
    _fundingNoteController.clear();
    _selectedFundingCurrency = OpportunityMetadata.supportedCurrencies.first;

    if (!OpportunityMetadata.usesStructuredFields(type)) {
      return;
    }

    _selectedSalaryCurrency ??= OpportunityMetadata.supportedCurrencies.first;

    final employmentOptions =
        OpportunityMetadata.employmentTypesForOpportunityType(type);

    if (OpportunityType.parse(type) == OpportunityType.internship) {
      _selectedEmploymentType = OpportunityType.internship;
      return;
    }

    if (!employmentOptions.contains(_selectedEmploymentType)) {
      _selectedEmploymentType = null;
    }
  }

  List<String> get _employmentTypeOptions =>
      OpportunityMetadata.employmentTypesForOpportunityType(_selectedType);

  String _employmentTypeLabel(String type, AppLocalizations l10n) {
    return switch (type) {
      'full_time' => l10n.employmentTypeFullTime,
      'part_time' => l10n.employmentTypePartTime,
      'internship' => l10n.employmentTypeInternship,
      'contract' => l10n.employmentTypeContract,
      'temporary' => l10n.employmentTypeTemporary,
      'freelance' => l10n.employmentTypeFreelance,
      _ => _titleCaseLabel(type),
    };
  }

  String _formatNumberForInput(num? value) {
    if (value == null) {
      return '';
    }

    if (value % 1 == 0) {
      return value.toStringAsFixed(0);
    }

    return value.toString();
  }

  String _titleCaseLabel(String rawValue) {
    return rawValue
        .split(RegExp(r'[_\s]+'))
        .where((part) => part.isNotEmpty)
        .map(
          (part) =>
              '${part[0].toUpperCase()}${part.substring(1).toLowerCase()}',
        )
        .join(' ');
  }

  Widget _buildEarlyAccessToggle() {
    final l10n = _l10n;
    final colors = AppColors.of(context);

    // If already reviewed (approved/rejected), show read-only status.
    final isReviewed =
        _currentEarlyAccessStatus == 'approved' ||
        _currentEarlyAccessStatus == 'rejected';

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _requestEarlyAccess ? colors.accentSoft : colors.surfaceMuted,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: _requestEarlyAccess
              ? colors.accent.withValues(alpha: 0.4)
              : colors.border,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.workspace_premium_rounded,
                size: 18,
                color: _requestEarlyAccess ? colors.accent : colors.textMuted,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  l10n.earlyAccessLabel,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: _requestEarlyAccess
                        ? colors.accent
                        : colors.textPrimary,
                  ),
                ),
              ),
              if (!isReviewed)
                Switch.adaptive(
                  value: _requestEarlyAccess,
                  activeThumbColor: colors.accent,
                  onChanged: _isSubmitting
                      ? null
                      : (v) => setState(() => _requestEarlyAccess = v),
                ),
              if (isReviewed)
                _EarlyAccessStatusChip(status: _currentEarlyAccessStatus),
            ],
          ),
          if (_requestEarlyAccess && !isReviewed) ...[
            const SizedBox(height: 6),
            Text(
              'Request early access for premium students. Admin must approve before it activates.',
              style: TextStyle(fontSize: 11, color: colors.textSecondary),
            ),
          ],
          if (_currentEarlyAccessStatus == 'pending') ...[
            const SizedBox(height: 6),
            Text(
              l10n.earlyAccessPendingStatus,
              style: TextStyle(
                fontSize: 11,
                color: colors.warning,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _EarlyAccessStatusChip extends StatelessWidget {
  final String status;
  const _EarlyAccessStatusChip({required this.status});

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    final (label, color) = switch (status) {
      'approved' => ('Approved', colors.success),
      'rejected' => ('Rejected', colors.danger),
      'pending' => ('Pending', colors.warning),
      'expired' => ('Expired', colors.textMuted),
      _ => ('None', colors.textMuted),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w700,
          color: color,
        ),
      ),
    );
  }
}
