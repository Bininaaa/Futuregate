import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../l10n/generated/app_localizations.dart';
import '../../providers/auth_provider.dart';
import '../../providers/company_provider.dart';
import '../../theme/app_colors.dart';
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
import '../../widgets/shared/posting_language_selector.dart';

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

  Color get _typeColor => OpportunityType.color(_selectedType);
  bool get _usesStructuredFields =>
      OpportunityMetadata.usesStructuredFields(_selectedType);
  bool get _isInternship =>
      OpportunityType.parse(_selectedType) == OpportunityType.internship;
  bool get _isSponsoring =>
      OpportunityType.parse(_selectedType) == OpportunityType.sponsoring;

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
    final l10n = AppLocalizations.of(context)!;

    return AppShellBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          title: Text(
            _isEditMode ? 'Edit Opportunity' : 'Create Opportunity',
            style: GoogleFonts.poppins(
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
                        ? 'Save Changes'
                        : 'Publish ${OpportunityType.label(_selectedType, l10n)}',
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
                          title: 'Basic Information',
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildField(
                                controller: _titleController,
                                label: 'Opportunity title',
                                hint: _titleHintForType(),
                                validator: _validateTitle,
                              ),
                              const SizedBox(height: 10),
                              PostingLanguageSelector(
                                value: _originalLanguage,
                                onChanged: (v) =>
                                    setState(() => _originalLanguage = v),
                                activeColor: CompanyDashboardPalette.primary,
                                borderColor: CompanyDashboardPalette.border,
                                textColor:
                                    CompanyDashboardPalette.textSecondary,
                                iconColor:
                                    CompanyDashboardPalette.textSecondary,
                              ),
                              const SizedBox(height: 14),
                              _buildSectionLabel('Opportunity type'),
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
                              _buildSectionLabel('Publishing status'),
                              const SizedBox(height: 10),
                              Row(
                                children: [
                                  Expanded(
                                    child: _buildStatusChip(
                                      label: 'Open',
                                      value: 'open',
                                      subtitle: 'Visible to students',
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: _buildStatusChip(
                                      label: 'Closed',
                                      value: 'closed',
                                      subtitle: 'Saved privately',
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 14),
                              _buildField(
                                controller: _locationController,
                                label: 'Location',
                                hint: _locationHintForType(),
                                validator: _validateLocation,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 12),
                        _buildSectionCard(
                          title: 'Description',
                          child: _buildField(
                            controller: _descriptionController,
                            label: OpportunityType.descriptionLabel(
                              _selectedType,
                              l10n,
                            ),
                            hint: OpportunityType.descriptionHint(
                              _selectedType,
                              l10n,
                            ),
                            maxLines: 6,
                            validator: _validateDescription,
                          ),
                        ),
                        const SizedBox(height: 12),
                        _buildSectionCard(
                          title: OpportunityType.requirementsLabel(
                            _selectedType,
                            l10n,
                          ),
                          subtitle: _requirementsSectionSubtitle(),
                          child: AppEditableListField(
                            theme: _theme,
                            label: 'Checklist',
                            hint: _isSponsoring
                                ? 'Type one eligibility rule, then press Enter'
                                : 'Type one requirement, then press Enter',
                            values: _requirementItems,
                            onChanged: (items) =>
                                setState(() => _requirementItems = items),
                            listController: _requirementsListController,
                            validator: _validateRequirementItems,
                            splitOnCommas: false,
                            emptyText: _isSponsoring
                                ? 'Add eligibility rules, documents, or selection criteria.'
                                : 'Add the skills, background, or tools students need.',
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
    final l10n = AppLocalizations.of(context)!;
    final statusColor = _selectedStatus == 'open'
        ? CompanyDashboardPalette.success
        : CompanyDashboardPalette.textSecondary;

    return AppFormHeaderCard(
      theme: _theme,
      icon: OpportunityType.icon(_selectedType),
      title: OpportunityType.headline(_selectedType, l10n),
      subtitle: _isEditMode
          ? 'Update the fields below and save.'
          : 'Fill in the fields below, then publish.',
      badges: <AppBadgeData>[
        AppBadgeData(
          label: OpportunityType.label(_selectedType, l10n),
          icon: OpportunityType.icon(_selectedType),
          color: _typeColor,
        ),
        AppBadgeData(
          label: _selectedStatus == 'open' ? 'Open' : 'Closed',
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
      title: _usesStructuredFields || _isSponsoring ? 'Logistics' : 'Publish',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildField(
            controller: _deadlineController,
            label: 'Application deadline',
            hint: 'Select a closing date',
            validator: _validateDeadline,
            onTap: _pickDate,
            readOnly: true,
            suffixIcon: const Icon(Icons.calendar_today),
          ),
          if (_isSponsoring) ...[
            const SizedBox(height: 14),
            _buildSectionLabel('Company funding'),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: _buildField(
                    controller: _fundingAmountController,
                    label: 'Funding amount',
                    hint: 'Funding amount',
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
                    label: 'Funding currency',
                    hint: 'Currency',
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
              label: 'Funding note',
              hint: 'Optional support details shown to students',
              maxLines: 2,
              validator: _validateFundingNote,
            ),
          ],
          if (_usesStructuredFields) ...[
            const SizedBox(height: 14),
            _buildSectionLabel(
              _isInternship
                  ? 'Internship compensation'
                  : 'Compensation & format',
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: _buildField(
                    controller: _salaryMinController,
                    label: 'Salary minimum',
                    hint: 'Salary min',
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
                    label: 'Salary maximum',
                    hint: 'Salary max',
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
                    label: 'Currency',
                    hint: 'Currency',
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
                    label: 'Salary period',
                    hint: 'Salary period',
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
                    label: 'Employment type',
                    hint: 'Employment type',
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
                    label: 'Work mode',
                    hint: 'Work mode',
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
              label: 'Paid status',
              hint: 'Paid status',
              items: [
                DropdownMenuItem<bool>(
                  value: true,
                  child: Text(AppLocalizations.of(context)!.paidLabel),
                ),
                DropdownMenuItem<bool>(
                  value: false,
                  child: Text(AppLocalizations.of(context)!.unpaidLabel),
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
                label: 'Duration',
                hint: 'Duration, e.g. 2 months',
                validator: _validateDuration,
              ),
            ],
            const SizedBox(height: 12),
            _buildField(
              controller: _compensationTextController,
              label: 'Compensation note',
              hint: 'Optional compensation note for detail screens',
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
      style: GoogleFonts.poppins(
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

  String _titleHintForType() {
    switch (_selectedType) {
      case OpportunityType.internship:
        return 'e.g. Flutter Internship - Mobile Team';
      case OpportunityType.sponsoring:
        return 'e.g. Student Innovation Sponsoring Program';
      case OpportunityType.job:
      default:
        return 'e.g. Junior Flutter Developer';
    }
  }

  String _locationHintForType() {
    switch (_selectedType) {
      case OpportunityType.sponsoring:
        return 'e.g. Algeria-wide or Algiers';
      case OpportunityType.internship:
      case OpportunityType.job:
      default:
        return 'e.g. Algiers, Algeria';
    }
  }

  String? _validateTitle(String? value) {
    final text = value?.trim() ?? '';
    if (text.isEmpty) {
      return 'Title is required';
    }
    if (text.length < 4) {
      return 'Use at least 4 characters';
    }
    return null;
  }

  String? _validateDescription(String? value) {
    final text = value?.trim() ?? '';
    if (text.isEmpty) {
      return 'Description is required';
    }
    if (text.length < 20) {
      return 'Please add a little more detail';
    }
    return null;
  }

  String? _validateLocation(String? value) {
    final text = value?.trim() ?? '';
    if (text.isEmpty) {
      return 'Location is required';
    }
    return null;
  }

  String? _validateRequirementItems(List<String> items) {
    if (items.where((item) => item.trim().isNotEmpty).isEmpty) {
      return _selectedType == OpportunityType.sponsoring
          ? 'Add at least one eligibility item'
          : 'Add at least one requirement';
    }
    return null;
  }

  String? _validateDeadline(String? value) {
    final text = value?.trim() ?? '';
    if (text.isEmpty) {
      return 'Application deadline is required';
    }

    final parsed =
        _applicationDeadline ?? OpportunityMetadata.parseDateTimeLike(text);
    if (parsed == null) {
      return 'Use a valid date';
    }

    final today = DateTime.now();
    final normalizedToday = DateTime(today.year, today.month, today.day);
    final normalizedDeadline = DateTime(parsed.year, parsed.month, parsed.day);
    if (normalizedDeadline.isBefore(normalizedToday)) {
      return 'Deadline cannot be in the past';
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
      return 'Enter a valid number';
    }

    if (minValue != null && maxValue != null && maxValue < minValue) {
      return 'Min cannot exceed max';
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
      return 'Enter a valid number';
    }

    if (minValue != null && maxValue != null && maxValue < minValue) {
      return 'Max must be at least min';
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
      return 'Add a clearer duration';
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
      return 'Add a funding amount or note';
    }
    if (text.isNotEmpty && parsed == null) {
      return 'Enter a valid amount';
    }
    if (parsed != null && parsed < 0) {
      return 'Amount cannot be negative';
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
      return 'Add a funding note or amount';
    }
    return null;
  }

  String _requirementsSectionSubtitle() {
    return _isSponsoring
        ? 'Add each eligibility point separately so students see a clean checklist.'
        : 'Add each requirement separately so students see a clean checklist.';
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
      helpText: 'Select deadline',
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
        'Sign in to continue publishing opportunities.',
        title: 'Login required',
        type: AppFeedbackType.warning,
      );
      return;
    }

    final deadlineDate =
        _applicationDeadline ??
        OpportunityMetadata.parseDateTimeLike(_deadlineController.text);
    final structuredData = _buildStructuredPayload();
    final requirementText = _requirementItems.join('\n');
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
        title: _isEditMode ? 'Update unavailable' : 'Publish unavailable',
        type: AppFeedbackType.error,
      );
      return;
    }

    final l10n = AppLocalizations.of(context)!;
    context.showAppSnackBar(
      _isEditMode
          ? 'Your opportunity details have been updated.'
          : '${OpportunityType.label(_selectedType, l10n)} published successfully.',
      title: _isEditMode ? 'Opportunity updated' : 'Opportunity published',
      type: AppFeedbackType.success,
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
}
