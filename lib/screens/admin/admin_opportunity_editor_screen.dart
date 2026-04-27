import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/opportunity_model.dart';
import '../../providers/admin_provider.dart';
import '../../providers/auth_provider.dart';
import '../../utils/admin_palette.dart';
import '../../utils/opportunity_metadata.dart';
import '../../l10n/generated/app_localizations.dart';
import '../../theme/locale_controller.dart';
import '../../utils/admin_identity.dart';
import '../../utils/content_language.dart';
import '../../utils/opportunity_type.dart';
import '../../widgets/opportunity_type_selector.dart';
import '../../widgets/shared/app_content_system.dart';
import '../../widgets/shared/app_feedback.dart';
import 'admin_editor_widgets.dart';

class AdminOpportunityEditorScreen extends StatefulWidget {
  final Map<String, dynamic>? initialOpportunity;

  const AdminOpportunityEditorScreen({super.key, this.initialOpportunity});

  @override
  State<AdminOpportunityEditorScreen> createState() =>
      _AdminOpportunityEditorScreenState();
}

class _AdminOpportunityEditorScreenState
    extends State<AdminOpportunityEditorScreen> {
  final _formKey = GlobalKey<FormState>();
  final _publisherController = TextEditingController();
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

  String _type = OpportunityType.job;
  String _status = 'open';
  String? _salaryCurrency = OpportunityMetadata.supportedCurrencies.first;
  String? _salaryPeriod;
  String? _fundingCurrency = OpportunityMetadata.supportedCurrencies.first;
  String? _employmentType;
  String? _workMode;
  bool? _isPaid;
  DateTime? _applicationDeadline;
  String _originalLanguage = 'fr';
  bool _isSubmitting = false;

  bool get _isEditing => widget.initialOpportunity != null;
  bool get _usesStructuredFields =>
      OpportunityMetadata.usesStructuredFields(_type);
  bool get _isInternship =>
      OpportunityType.parse(_type) == OpportunityType.internship;
  bool get _isSponsoring =>
      OpportunityType.parse(_type) == OpportunityType.sponsoring;

  @override
  void initState() {
    super.initState();
    _publisherController.text = AdminIdentity.publicName;
    _originalLanguage = _preferredPostingLanguage();

    final raw = widget.initialOpportunity;
    if (raw == null) return;

    final opportunity = OpportunityModel.fromMap(raw);
    _publisherController.text =
        raw['companyName']?.toString().trim().isNotEmpty == true
        ? AdminIdentity.sanitizeLegacyAdminLabel(raw['companyName'].toString())
        : _publisherController.text;
    _originalLanguage = ContentLanguage.normalizeCode(
      opportunity.originalLanguage,
      fallback: _preferredPostingLanguage(),
    );
    _titleController.text = opportunity.title;
    _descriptionController.text = opportunity.description;
    _locationController.text = opportunity.location;
    _requirementItems = opportunity.requirementItems.isNotEmpty
        ? List<String>.from(opportunity.requirementItems)
        : OpportunityMetadata.extractRequirementItems(
            raw,
            fallbackText: opportunity.requirements,
          );
    _type = opportunity.type;
    _status = opportunity.effectiveStatus() == 'closed' ? 'closed' : 'open';
    final deadline =
        opportunity.applicationDeadline ??
        OpportunityMetadata.parseDateTimeLike(opportunity.deadline);
    if (deadline != null) {
      _applicationDeadline = DateTime(
        deadline.year,
        deadline.month,
        deadline.day,
      );
      _deadlineController.text = OpportunityMetadata.formatDateForStorage(
        deadline,
      );
    } else {
      _deadlineController.text = opportunity.deadline;
    }
    _salaryMinController.text = _formatNum(opportunity.salaryMin);
    _salaryMaxController.text = _formatNum(opportunity.salaryMax);
    _compensationTextController.text = opportunity.compensationText ?? '';
    _fundingAmountController.text = _formatNum(
      opportunity.fundingAmount ??
          (_isSponsoring ? opportunity.salaryMin : null),
    );
    _fundingNoteController.text =
        opportunity.fundingNote ??
        (_isSponsoring ? opportunity.compensationText ?? '' : '');
    _durationController.text = opportunity.duration ?? '';
    _salaryCurrency = opportunity.salaryCurrency ?? _salaryCurrency;
    _fundingCurrency =
        opportunity.fundingCurrency ??
        opportunity.salaryCurrency ??
        _fundingCurrency;
    _salaryPeriod = opportunity.salaryPeriod;
    _employmentType = opportunity.employmentType;
    _workMode = opportunity.workMode;
    _isPaid = opportunity.isPaid;
    _applyTypeDefaults();
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

  @override
  void dispose() {
    _publisherController.dispose();
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
    return AdminEditorScaffold(
      title: _isEditing
          ? l10n.editAdminOpportunityTitle
          : l10n.publishAdminOpportunityTitle,
      submitLabel: _isEditing
          ? l10n.saveOpportunityChangesLabel
          : l10n.publishLabel,
      icon: Icons.work_outline_rounded,
      accentColor: OpportunityType.color(_type),
      subtitle: _isEditing
          ? l10n.uiUpdateTheFieldsBelowAndSave
          : l10n.uiFillInTheFieldsBelowThenPublish,
      isSubmitting: _isSubmitting,
      onSubmit: _submit,
      child: Form(
        key: _formKey,
        autovalidateMode: AutovalidateMode.onUserInteraction,
        child: Column(
          children: [
            AdminEditorSection(
              title: l10n.uiBasicInformation,
              child: Column(
                children: [
                  AdminEditorField(
                    controller: _publisherController,
                    label: 'Publisher name',
                    hint: 'e.g. FutureGate Admin',
                    validator: adminRequiredMin('Publisher name', min: 3),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: AdminEditorChoiceCard(
                          label: l10n.uiOpen,
                          subtitle: l10n.openStatusSubtitle,
                          selected: _status == 'open',
                          color: AdminPalette.success,
                          icon: Icons.visibility_outlined,
                          onTap: () => setState(() => _status = 'open'),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: AdminEditorChoiceCard(
                          label: l10n.closedStatusLabel,
                          subtitle: l10n.savedHiddenLabel,
                          selected: _status == 'closed',
                          color: AdminPalette.textMuted,
                          icon: Icons.lock_outline_rounded,
                          onTap: () => setState(() => _status = 'closed'),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  AdminEditorField(
                    controller: _titleController,
                    label: l10n.opportunityTitleLabel,
                    hint: _titleHintForType(l10n),
                    validator: adminRequiredMin(
                      l10n.opportunityTitleLabel,
                      min: 4,
                    ),
                  ),
                  const SizedBox(height: 12),
                  AdminEditorDropdown<String>(
                    value: _originalLanguage,
                    label: l10n.originalLanguageFieldLabel,
                    items: [
                      DropdownMenuItem(
                        value: ContentLanguage.french,
                        child: Text(l10n.languageFrench),
                      ),
                      DropdownMenuItem(
                        value: ContentLanguage.english,
                        child: Text(l10n.languageEnglish),
                      ),
                      DropdownMenuItem(
                        value: ContentLanguage.arabic,
                        child: Text(l10n.languageArabic),
                      ),
                    ],
                    onChanged: (value) {
                      if (value == null) return;
                      setState(() => _originalLanguage = value);
                    },
                  ),
                  const SizedBox(height: 12),
                  OpportunityTypeSelector(
                    selected: _type,
                    onChanged: (value) {
                      if (_type == value) return;
                      setState(() {
                        _type = value;
                        _applyTypeDefaults();
                      });
                    },
                  ),
                  const SizedBox(height: 12),
                  AdminEditorField(
                    controller: _locationController,
                    label: l10n.locationLabel,
                    hint: _locationHintForType(l10n),
                    validator: adminRequiredMin(l10n.locationLabel),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            AdminEditorSection(
              title: l10n.descriptionSectionTitle,
              child: AdminEditorField(
                controller: _descriptionController,
                label: 'Description',
                hint: 'Describe the role, scope, and value clearly',
                maxLines: 6,
                minLength: 60,
                helperText:
                    'Add enough detail for students to understand scope, expectations, and value.',
                validator: adminRequiredMin('Description', min: 60),
              ),
            ),
            const SizedBox(height: 12),
            AdminEditorSection(
              title: OpportunityType.requirementsLabel(_type, l10n),
              subtitle: _requirementsSectionSubtitle(),
              child: AdminEditorListField(
                label: '',
                hint: _type == OpportunityType.sponsoring
                    ? 'Type one eligibility rule, then press Enter'
                    : 'Type one requirement, then press Enter',
                values: _requirementItems,
                onChanged: (items) => setState(() => _requirementItems = items),
                listController: _requirementsListController,
                validator: _validateRequirementItems,
                splitOnCommas: false,
                emptyText: '',
              ),
            ),
            const SizedBox(height: 12),
            AdminEditorSection(
              title: l10n.logisticsTitle,
              child: Column(
                children: [
                  AdminEditorField(
                    controller: _deadlineController,
                    label: 'Application deadline',
                    hint: 'Select a closing date',
                    readOnly: true,
                    suffixIcon: const Icon(Icons.calendar_today_rounded),
                    onTap: _pickDeadline,
                    validator: _validateDeadline,
                  ),
                  if (_isSponsoring) ...[
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: AdminEditorField(
                            controller: _fundingAmountController,
                            label: 'Funding amount',
                            hint: 'e.g. 250000',
                            keyboardType: const TextInputType.numberWithOptions(
                              decimal: true,
                            ),
                            validator: _validateFundingAmount,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: AdminEditorDropdown<String>(
                            value: _fundingCurrency,
                            label: 'Funding currency',
                            items: OpportunityMetadata.supportedCurrencies
                                .map(
                                  (item) => DropdownMenuItem(
                                    value: item,
                                    child: Text(item),
                                  ),
                                )
                                .toList(),
                            onChanged: (value) =>
                                setState(() => _fundingCurrency = value),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    AdminEditorField(
                      controller: _fundingNoteController,
                      label: 'Funding note',
                      hint: 'Optional support details shown to students',
                      maxLines: 2,
                      validator: _validateFundingNote,
                    ),
                  ],
                  if (_usesStructuredFields) ...[
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: AdminEditorField(
                            controller: _salaryMinController,
                            label: 'Salary minimum',
                            hint: 'e.g. 60000',
                            keyboardType: TextInputType.number,
                            validator: _validateSalaryMin,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: AdminEditorField(
                            controller: _salaryMaxController,
                            label: 'Salary maximum',
                            hint: 'e.g. 90000',
                            keyboardType: TextInputType.number,
                            validator: _validateSalaryMax,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: AdminEditorDropdown<String>(
                            value: _salaryCurrency,
                            label: 'Currency',
                            items: OpportunityMetadata.supportedCurrencies
                                .map(
                                  (item) => DropdownMenuItem(
                                    value: item,
                                    child: Text(item),
                                  ),
                                )
                                .toList(),
                            onChanged: (value) =>
                                setState(() => _salaryCurrency = value),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: AdminEditorDropdown<String>(
                            value: _salaryPeriod,
                            label: 'Salary period',
                            items: OpportunityMetadata.salaryPeriods
                                .map(
                                  (item) => DropdownMenuItem(
                                    value: item,
                                    child: Text(adminTitleCase(item)),
                                  ),
                                )
                                .toList(),
                            onChanged: (value) =>
                                setState(() => _salaryPeriod = value),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: AdminEditorDropdown<String>(
                            value: _employmentType,
                            label: 'Employment type',
                            items: _employmentTypeOptions
                                .map(
                                  (item) => DropdownMenuItem(
                                    value: item,
                                    child: Text(
                                      _employmentTypeLabel(item, l10n),
                                    ),
                                  ),
                                )
                                .toList(),
                            onChanged: (value) =>
                                setState(() => _employmentType = value),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: AdminEditorDropdown<String>(
                            value: _workMode,
                            label: 'Work mode',
                            items: OpportunityMetadata.workModes
                                .map(
                                  (item) => DropdownMenuItem(
                                    value: item,
                                    child: Text(
                                      OpportunityMetadata.formatWorkMode(
                                            item,
                                          ) ??
                                          adminTitleCase(item),
                                    ),
                                  ),
                                )
                                .toList(),
                            onChanged: (value) =>
                                setState(() => _workMode = value),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    AdminEditorDropdown<bool>(
                      value: _isPaid,
                      label: 'Paid status',
                      items: [
                        DropdownMenuItem(
                          value: true,
                          child: Text(l10n.paidLabel),
                        ),
                        DropdownMenuItem(
                          value: false,
                          child: Text(l10n.unpaidLabel),
                        ),
                      ],
                      onChanged: (value) => setState(() => _isPaid = value),
                    ),
                    if (_isInternship) ...[
                      const SizedBox(height: 12),
                      AdminEditorField(
                        controller: _durationController,
                        label: 'Duration',
                        hint: 'e.g. 3 months',
                      ),
                    ],
                    const SizedBox(height: 12),
                    AdminEditorField(
                      controller: _compensationTextController,
                      label: 'Compensation note',
                      hint: 'Optional note shown on detail screens',
                      maxLines: 2,
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

  Future<void> _pickDeadline() async {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final initialDate =
        _applicationDeadline ??
        OpportunityMetadata.parseDateTimeLike(_deadlineController.text) ??
        today.add(const Duration(days: 30));
    final picked = await showDatePicker(
      context: context,
      initialDate: initialDate.isBefore(today) ? today : initialDate,
      firstDate: today,
      lastDate: DateTime(2035),
      helpText: 'Select deadline',
    );
    if (picked == null) return;

    final normalized = DateTime(picked.year, picked.month, picked.day);
    setState(() {
      _applicationDeadline = normalized;
      _deadlineController.text = OpportunityMetadata.formatDateForStorage(
        normalized,
      );
    });
  }

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();
    _requirementsListController.commitPendingInput();
    if (!_formKey.currentState!.validate()) return;

    final auth = context.read<AuthProvider>().userModel;
    if (auth == null) return;

    setState(() => _isSubmitting = true);

    final deadline =
        _applicationDeadline ??
        OpportunityMetadata.parseDateTimeLike(_deadlineController.text);
    final currentAdminLogo = (auth.logo ?? '').trim().isNotEmpty
        ? (auth.logo ?? '').trim()
        : auth.profileImage.trim();
    final existingOpportunity =
        widget.initialOpportunity ?? const <String, dynamic>{};
    String existingString(String key) =>
        (existingOpportunity[key] ?? '').toString().trim();
    final existingCompanyId = existingString('companyId');
    final isOwnedAdminPost =
        !_isEditing ||
        existingCompanyId.isEmpty ||
        existingCompanyId == auth.uid;
    final publisherUserId = isOwnedAdminPost ? auth.uid : existingCompanyId;
    final publisherLogo = _isEditing
        ? existingString('companyLogo')
        : currentAdminLogo;
    final creatorId = isOwnedAdminPost ? auth.uid : existingString('createdBy');
    final creatorRole = isOwnedAdminPost
        ? 'admin'
        : (existingString('createdByRole').isNotEmpty
              ? existingString('createdByRole')
              : 'admin');
    final requirementText = _requirementItems.join('\n');
    final payload = <String, dynamic>{
      'companyId': publisherUserId,
      'companyName': AdminIdentity.publisherLabel(_publisherController.text),
      'companyLogo': publisherLogo,
      'createdBy': creatorId,
      'createdByRole': creatorRole,
      'title': _titleController.text.trim(),
      'description': _descriptionController.text.trim(),
      'type': _type,
      'location': _locationController.text.trim(),
      'requirements': requirementText,
      'requirementItems': _requirementItems,
      'status': _status,
      'deadline': deadline == null
          ? _deadlineController.text.trim()
          : OpportunityMetadata.formatDateForStorage(deadline),
      'applicationDeadline': deadline == null
          ? null
          : OpportunityMetadata.normalizeDateToEndOfDay(deadline),
      'salaryMin': OpportunityMetadata.parseNullableNum(
        _salaryMinController.text,
      ),
      'salaryMax': OpportunityMetadata.parseNullableNum(
        _salaryMaxController.text,
      ),
      'salaryCurrency': _salaryCurrency,
      'salaryPeriod': _salaryPeriod,
      'compensationText': OpportunityMetadata.sanitizeText(
        _compensationTextController.text,
      ),
      'fundingAmount': OpportunityMetadata.parseNullableNum(
        _fundingAmountController.text,
      ),
      'fundingCurrency': _fundingCurrency,
      'fundingNote': OpportunityMetadata.sanitizeText(
        _fundingNoteController.text,
      ),
      'employmentType': _employmentType,
      'workMode': _workMode,
      'isPaid': _isPaid,
      'duration': _isInternship
          ? OpportunityMetadata.normalizeDuration(_durationController.text)
          : null,
      'originalLanguage': _originalLanguage,
    };

    final provider = context.read<AdminProvider>();
    final error = _isEditing
        ? await provider.updateAdminOpportunity(
            widget.initialOpportunity!['id'].toString(),
            payload,
          )
        : await provider.createAdminOpportunity(payload);

    if (!mounted) return;
    setState(() => _isSubmitting = false);

    if (error != null) {
      context.showAppSnackBar(
        error,
        title: _isEditing ? 'Update unavailable' : 'Publish unavailable',
        type: AppFeedbackType.error,
      );
      return;
    }

    context.showAppSnackBar(
      _isEditing
          ? 'Admin opportunity updated successfully.'
          : 'Admin opportunity published successfully.',
      title: _isEditing ? 'Opportunity updated' : 'Opportunity published',
      type: AppFeedbackType.success,
    );
    Navigator.of(context).pop(true);
  }

  void _applyTypeDefaults() {
    if (_isSponsoring) {
      _salaryMinController.clear();
      _salaryMaxController.clear();
      _compensationTextController.clear();
      _salaryPeriod = null;
      _employmentType = null;
      _workMode = null;
      _isPaid = null;
      _durationController.clear();
      _fundingCurrency ??= OpportunityMetadata.supportedCurrencies.first;
      return;
    }

    _fundingAmountController.clear();
    _fundingNoteController.clear();
    _fundingCurrency = OpportunityMetadata.supportedCurrencies.first;

    if (!_usesStructuredFields) {
      _salaryMinController.clear();
      _salaryMaxController.clear();
      _compensationTextController.clear();
      _salaryPeriod = null;
      _employmentType = null;
      _workMode = null;
      _isPaid = null;
      _durationController.clear();
      return;
    }

    _salaryCurrency ??= OpportunityMetadata.supportedCurrencies.first;
    if (_isInternship) {
      _employmentType = OpportunityType.internship;
      return;
    }
    if (!_employmentTypeOptions.contains(_employmentType)) {
      _employmentType = null;
    }
  }

  String _requirementsSectionSubtitle() {
    return _isSponsoring
        ? 'Add each eligibility point separately so students see a clean checklist.'
        : 'Add each requirement separately so students see a clean checklist.';
  }

  String _titleHintForType(AppLocalizations l10n) {
    return switch (OpportunityType.parse(_type)) {
      OpportunityType.internship => l10n.opportunityTitleHintInternship,
      OpportunityType.sponsoring => l10n.opportunityTitleHintSponsoring,
      _ => l10n.opportunityTitleHintJob,
    };
  }

  String _locationHintForType(AppLocalizations l10n) {
    return switch (OpportunityType.parse(_type)) {
      OpportunityType.sponsoring => l10n.opportunityLocationHintSponsoring,
      _ => l10n.opportunityLocationHintDefault,
    };
  }

  List<String> get _employmentTypeOptions =>
      OpportunityMetadata.employmentTypesForOpportunityType(_type);

  String _employmentTypeLabel(String type, AppLocalizations l10n) {
    return switch (type) {
      'full_time' => l10n.employmentTypeFullTime,
      'part_time' => l10n.employmentTypePartTime,
      'internship' => l10n.employmentTypeInternship,
      'contract' => l10n.employmentTypeContract,
      'temporary' => l10n.employmentTypeTemporary,
      'freelance' => l10n.employmentTypeFreelance,
      _ => adminTitleCase(type),
    };
  }

  String? _validateRequirementItems(List<String> items) {
    if (items.where((item) => item.trim().isNotEmpty).isEmpty) {
      return _isSponsoring
          ? 'Add at least one eligibility item'
          : 'Add at least one requirement';
    }
    return null;
  }

  String? _validateDeadline(String? value) {
    final text = value?.trim() ?? '';
    if (text.isEmpty) return 'Deadline is required';

    final parsed =
        _applicationDeadline ?? OpportunityMetadata.parseDateTimeLike(text);
    if (parsed == null) return 'Use a valid date';

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final normalized = DateTime(parsed.year, parsed.month, parsed.day);
    if (normalized.isBefore(today)) return 'Deadline cannot be in the past';
    return null;
  }

  String? _validateSalaryMin(String? value) {
    final minValue = OpportunityMetadata.parseNullableNum(
      _salaryMinController.text,
    );
    final maxValue = OpportunityMetadata.parseNullableNum(
      _salaryMaxController.text,
    );
    if ((value ?? '').trim().isNotEmpty && minValue == null) {
      return 'Enter a valid number';
    }
    if (minValue != null && maxValue != null && maxValue < minValue) {
      return 'Min cannot exceed max';
    }
    return null;
  }

  String? _validateSalaryMax(String? value) {
    final minValue = OpportunityMetadata.parseNullableNum(
      _salaryMinController.text,
    );
    final maxValue = OpportunityMetadata.parseNullableNum(
      _salaryMaxController.text,
    );
    if ((value ?? '').trim().isNotEmpty && maxValue == null) {
      return 'Enter a valid number';
    }
    if (minValue != null && maxValue != null && maxValue < minValue) {
      return 'Max must be at least min';
    }
    return null;
  }

  String? _validateFundingAmount(String? value) {
    if (!_isSponsoring) {
      return null;
    }

    final text = value?.trim() ?? '';
    final note = _fundingNoteController.text.trim();
    final parsed = OpportunityMetadata.parseNullableNum(text);
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

  String _formatNum(num? value) {
    if (value == null) return '';
    return value % 1 == 0 ? value.toStringAsFixed(0) : value.toString();
  }
}
