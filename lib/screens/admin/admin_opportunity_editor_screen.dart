import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/opportunity_model.dart';
import '../../providers/admin_provider.dart';
import '../../providers/auth_provider.dart';
import '../../utils/admin_palette.dart';
import '../../utils/opportunity_metadata.dart';
import '../../utils/opportunity_type.dart';
import '../../widgets/opportunity_type_selector.dart';
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
  final _requirementsController = TextEditingController();
  final _deadlineController = TextEditingController();
  final _salaryMinController = TextEditingController();
  final _salaryMaxController = TextEditingController();
  final _compensationTextController = TextEditingController();
  final _durationController = TextEditingController();

  String _type = OpportunityType.job;
  String _status = 'open';
  String? _salaryCurrency = OpportunityMetadata.supportedCurrencies.first;
  String? _salaryPeriod;
  String? _employmentType;
  String? _workMode;
  bool? _isPaid;
  DateTime? _applicationDeadline;
  bool _isSubmitting = false;

  bool get _isEditing => widget.initialOpportunity != null;
  bool get _usesStructuredFields =>
      OpportunityMetadata.usesStructuredFields(_type);
  bool get _isInternship =>
      OpportunityType.parse(_type) == OpportunityType.internship;

  @override
  void initState() {
    super.initState();
    final auth = context.read<AuthProvider>().userModel;
    _publisherController.text = auth?.fullName.trim().isNotEmpty == true
        ? auth!.fullName.trim()
        : 'AvenirDZ Admin';

    final raw = widget.initialOpportunity;
    if (raw == null) return;

    final opportunity = OpportunityModel.fromMap(raw);
    _publisherController.text =
        raw['companyName']?.toString().trim().isNotEmpty == true
        ? raw['companyName'].toString().trim()
        : _publisherController.text;
    _titleController.text = opportunity.title;
    _descriptionController.text = opportunity.description;
    _locationController.text = opportunity.location;
    _requirementsController.text = opportunity.requirements;
    _type = opportunity.type;
    _status = opportunity.status == 'closed' ? 'closed' : 'open';
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
    _durationController.text = opportunity.duration ?? '';
    _salaryCurrency = opportunity.salaryCurrency ?? _salaryCurrency;
    _salaryPeriod = opportunity.salaryPeriod;
    _employmentType = opportunity.employmentType;
    _workMode = opportunity.workMode;
    _isPaid = opportunity.isPaid;
  }

  @override
  void dispose() {
    _publisherController.dispose();
    _titleController.dispose();
    _descriptionController.dispose();
    _locationController.dispose();
    _requirementsController.dispose();
    _deadlineController.dispose();
    _salaryMinController.dispose();
    _salaryMaxController.dispose();
    _compensationTextController.dispose();
    _durationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AdminEditorScaffold(
      title: _isEditing
          ? 'Edit Admin Opportunity'
          : 'Publish Admin Opportunity',
      submitLabel: _isEditing
          ? 'Save Opportunity Changes'
          : 'Publish Opportunity',
      icon: Icons.work_outline_rounded,
      accentColor: OpportunityType.color(_type),
      subtitle:
          'Create a platform-managed opportunity with the same structured filtering and detail quality used across the student opportunity catalog.',
      isSubmitting: _isSubmitting,
      onSubmit: _submit,
      child: Form(
        key: _formKey,
        child: Column(
          children: [
            AdminEditorSection(
              title: 'Basic Information',
              subtitle:
                  'Keep the core publisher, title, type, status, and location fields together so the listing starts from the same structure used everywhere else.',
              child: Column(
                children: [
                  AdminEditorField(
                    controller: _publisherController,
                    label: 'Publisher name',
                    hint: 'e.g. AvenirDZ Admin',
                    validator: adminRequiredMin('Publisher name', min: 3),
                  ),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      Expanded(
                        child: AdminEditorChoiceCard(
                          label: 'Open',
                          subtitle: 'Visible to students',
                          selected: _status == 'open',
                          color: AdminPalette.success,
                          icon: Icons.visibility_outlined,
                          onTap: () => setState(() => _status = 'open'),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: AdminEditorChoiceCard(
                          label: 'Closed',
                          subtitle: 'Saved but hidden',
                          selected: _status == 'closed',
                          color: AdminPalette.textMuted,
                          icon: Icons.lock_outline_rounded,
                          onTap: () => setState(() => _status = 'closed'),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  AdminEditorField(
                    controller: _titleController,
                    label: 'Opportunity title',
                    hint: 'e.g. Junior Flutter Developer',
                    validator: adminRequiredMin('Title', min: 4),
                  ),
                  const SizedBox(height: 14),
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
                  const SizedBox(height: 14),
                  AdminEditorField(
                    controller: _locationController,
                    label: 'Location',
                    hint: 'e.g. Algiers, Algeria',
                    validator: adminRequiredMin('Location'),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            AdminEditorSection(
              title: 'Description',
              subtitle:
                  'Give the role or program a clear narrative that will carry through cards and detail pages.',
              child: Column(
                children: [
                  AdminEditorField(
                    controller: _descriptionController,
                    label: 'Description',
                    hint: 'Describe the role, scope, and value clearly',
                    maxLines: 6,
                    validator: adminRequiredMin('Description', min: 20),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            AdminEditorSection(
              title: 'Requirements And Eligibility',
              subtitle:
                  'Surface the expectations or criteria clearly before students decide to apply.',
              child: Column(
                children: [
                  AdminEditorField(
                    controller: _requirementsController,
                    label: _type == OpportunityType.sponsoring
                        ? 'Eligibility'
                        : 'Requirements',
                    hint: _type == OpportunityType.sponsoring
                        ? 'Share eligibility and supporting details'
                        : 'Share the background, skills, or experience needed',
                    maxLines: 4,
                    validator: adminRequiredMin(
                      _type == OpportunityType.sponsoring
                          ? 'Eligibility'
                          : 'Requirements',
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            AdminEditorSection(
              title: 'Logistics',
              subtitle:
                  'Capture timing, compensation, and format details in one predictable publishing section.',
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
                  if (_usesStructuredFields) ...[
                    const SizedBox(height: 14),
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
                    const SizedBox(height: 14),
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
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        Expanded(
                          child: AdminEditorDropdown<String>(
                            value: _employmentType,
                            label: 'Employment type',
                            items: OpportunityMetadata.employmentTypes
                                .map(
                                  (item) => DropdownMenuItem(
                                    value: item,
                                    child: Text(
                                      OpportunityMetadata.formatEmploymentType(
                                            item,
                                          ) ??
                                          adminTitleCase(item),
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
                    const SizedBox(height: 14),
                    AdminEditorDropdown<bool>(
                      value: _isPaid,
                      label: 'Paid status',
                      items: const [
                        DropdownMenuItem(value: true, child: Text('Paid')),
                        DropdownMenuItem(value: false, child: Text('Unpaid')),
                      ],
                      onChanged: (value) => setState(() => _isPaid = value),
                    ),
                    if (_isInternship) ...[
                      const SizedBox(height: 14),
                      AdminEditorField(
                        controller: _durationController,
                        label: 'Duration',
                        hint: 'e.g. 3 months',
                      ),
                    ],
                    const SizedBox(height: 14),
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
    if (!_formKey.currentState!.validate()) return;

    final auth = context.read<AuthProvider>().userModel;
    if (auth == null) return;

    setState(() => _isSubmitting = true);

    final deadline =
        _applicationDeadline ??
        OpportunityMetadata.parseDateTimeLike(_deadlineController.text);
    final companyLogo = (auth.logo ?? '').trim().isNotEmpty
        ? (auth.logo ?? '').trim()
        : auth.profileImage.trim();
    final payload = <String, dynamic>{
      'companyId': auth.uid,
      'companyName': _publisherController.text.trim(),
      'companyLogo': companyLogo,
      'title': _titleController.text.trim(),
      'description': _descriptionController.text.trim(),
      'type': _type,
      'location': _locationController.text.trim(),
      'requirements': _requirementsController.text.trim(),
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
      'employmentType': _employmentType,
      'workMode': _workMode,
      'isPaid': _isPaid,
      'duration': _isInternship
          ? OpportunityMetadata.normalizeDuration(_durationController.text)
          : null,
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
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error)));
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          _isEditing
              ? 'Admin opportunity updated successfully'
              : 'Admin opportunity published successfully',
        ),
      ),
    );
    Navigator.of(context).pop(true);
  }

  void _applyTypeDefaults() {
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
      _employmentType ??= 'internship';
      return;
    }
    if (_employmentType == 'internship') {
      _employmentType = null;
    }
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

  String _formatNum(num? value) {
    if (value == null) return '';
    return value % 1 == 0 ? value.toStringAsFixed(0) : value.toString();
  }
}
