import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../providers/auth_provider.dart';
import '../../providers/company_provider.dart';
import '../../utils/opportunity_metadata.dart';
import '../../utils/opportunity_type.dart';
import '../../widgets/opportunity_type_selector.dart';

class PublishOpportunityScreen extends StatefulWidget {
  final String? opportunityId;

  const PublishOpportunityScreen({super.key, this.opportunityId});

  @override
  State<PublishOpportunityScreen> createState() =>
      _PublishOpportunityScreenState();
}

class _PublishOpportunityScreenState extends State<PublishOpportunityScreen> {
  static const Color vibrantOrange = Color(0xFFFF6700);
  static const Color strongBlue = Color(0xFF004E98);
  static const Color mediumBlue = Color(0xFF3A6EA5);
  static const Color softGray = Color(0xFFEBEBEB);

  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _locationController = TextEditingController();
  final _requirementsController = TextEditingController();
  final _deadlineController = TextEditingController();
  final _salaryMinController = TextEditingController();
  final _salaryMaxController = TextEditingController();
  final _compensationTextController = TextEditingController();
  final _durationController = TextEditingController();

  String _selectedType = OpportunityType.job;
  String _selectedStatus = 'open';
  String? _selectedSalaryCurrency =
      OpportunityMetadata.supportedCurrencies.first;
  String? _selectedSalaryPeriod;
  String? _selectedEmploymentType;
  String? _selectedWorkMode;
  bool? _isPaid;
  DateTime? _applicationDeadline;

  bool _isLoading = false;
  bool _isSubmitting = false;
  bool _isEditMode = false;

  Color get _typeColor => OpportunityType.color(_selectedType);
  bool get _usesStructuredFields =>
      OpportunityMetadata.usesStructuredFields(_selectedType);
  bool get _isInternship =>
      OpportunityType.parse(_selectedType) == OpportunityType.internship;

  @override
  void initState() {
    super.initState();
    if (widget.opportunityId != null) {
      _isEditMode = true;
      _loadOpportunity();
    }
  }

  Future<void> _loadOpportunity() async {
    setState(() => _isLoading = true);

    final provider = context.read<CompanyProvider>();
    final opp = await provider.getOpportunityById(widget.opportunityId!);

    if (opp != null) {
      _titleController.text = opp.title;
      _descriptionController.text = opp.description;
      _locationController.text = opp.location;
      _requirementsController.text = opp.requirements;
      _selectedType = OpportunityType.parse(opp.type);
      _selectedStatus = opp.status == 'closed' ? 'closed' : 'open';

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
      _durationController.text = opp.duration ?? '';

      _selectedSalaryCurrency =
          opp.salaryCurrency ??
          _selectedSalaryCurrency ??
          OpportunityMetadata.supportedCurrencies.first;
      _selectedSalaryPeriod = opp.salaryPeriod;
      _selectedEmploymentType = opp.employmentType;
      _selectedWorkMode = opp.workMode;
      _isPaid = opp.isPaid;

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
    return Scaffold(
      backgroundColor: softGray,
      appBar: AppBar(
        title: Text(
          _isEditMode ? 'Edit Opportunity' : 'Post Opportunity',
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.w600,
            color: strongBlue,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: strongBlue),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: vibrantOrange))
          : SafeArea(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
                child: Form(
                  key: _formKey,
                  autovalidateMode: AutovalidateMode.onUserInteraction,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildHeroCard(),
                      const SizedBox(height: 18),
                      _buildSectionCard(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildSectionLabel('Opportunity title'),
                            const SizedBox(height: 8),
                            _buildField(
                              controller: _titleController,
                              hint: _titleHintForType(),
                              validator: _validateTitle,
                            ),
                            const SizedBox(height: 18),
                            _buildSectionLabel('Opportunity type'),
                            const SizedBox(height: 6),
                            Text(
                              'Choose what students see first so the listing lands in the right category.',
                              style: GoogleFonts.poppins(
                                fontSize: 12,
                                color: mediumBlue,
                                height: 1.45,
                              ),
                            ),
                            const SizedBox(height: 12),
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
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      _buildSectionCard(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildSectionLabel('Publishing status'),
                            const SizedBox(height: 6),
                            Text(
                              'Open opportunities are visible to students. Closed ones stay saved but do not accept new applications.',
                              style: GoogleFonts.poppins(
                                fontSize: 12,
                                color: mediumBlue,
                                height: 1.45,
                              ),
                            ),
                            const SizedBox(height: 12),
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
                                    subtitle: 'Hidden for now',
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      _buildSectionCard(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildSectionLabel(
                              OpportunityType.descriptionLabel(_selectedType),
                            ),
                            const SizedBox(height: 8),
                            _buildField(
                              controller: _descriptionController,
                              hint: OpportunityType.descriptionHint(
                                _selectedType,
                              ),
                              maxLines: 6,
                              validator: _validateDescription,
                            ),
                            const SizedBox(height: 18),
                            _buildSectionLabel('Location'),
                            const SizedBox(height: 8),
                            _buildField(
                              controller: _locationController,
                              hint: _locationHintForType(),
                              validator: _validateLocation,
                            ),
                            const SizedBox(height: 18),
                            _buildSectionLabel(
                              OpportunityType.requirementsLabel(_selectedType),
                            ),
                            const SizedBox(height: 8),
                            _buildField(
                              controller: _requirementsController,
                              hint: OpportunityType.requirementsHint(
                                _selectedType,
                              ),
                              maxLines: 4,
                              validator: _validateRequirements,
                            ),
                            const SizedBox(height: 18),
                            _buildSectionLabel('Application deadline'),
                            const SizedBox(height: 8),
                            _buildField(
                              controller: _deadlineController,
                              hint: 'Select a closing date',
                              validator: _validateDeadline,
                              onTap: _pickDate,
                              readOnly: true,
                              suffixIcon: const Icon(Icons.calendar_today),
                            ),
                          ],
                        ),
                      ),
                      if (_usesStructuredFields) ...[
                        const SizedBox(height: 16),
                        _buildStructuredOpportunityCard(),
                      ],
                      const SizedBox(height: 24),
                      SizedBox(
                        width: double.infinity,
                        height: 54,
                        child: ElevatedButton(
                          onPressed: _isSubmitting ? null : _submit,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: vibrantOrange,
                            foregroundColor: Colors.white,
                            disabledBackgroundColor: vibrantOrange.withValues(
                              alpha: 0.5,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(18),
                            ),
                            elevation: 0,
                          ),
                          child: _isSubmitting
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2.4,
                                    color: Colors.white,
                                  ),
                                )
                              : Text(
                                  _isEditMode
                                      ? 'Save Changes'
                                      : 'Publish ${OpportunityType.label(_selectedType)}',
                                  style: GoogleFonts.poppins(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
    );
  }

  Widget _buildHeroCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [_typeColor.withValues(alpha: 0.18), Colors.white],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: _typeColor.withValues(alpha: 0.18)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: _typeColor.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(
              OpportunityType.icon(_selectedType),
              color: _typeColor,
              size: 26,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  OpportunityType.headline(_selectedType),
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: strongBlue,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  _selectedType == OpportunityType.sponsoring
                      ? 'Students will be notified when a sponsoring opportunity is published as open.'
                      : 'Use clear details and structured metadata so students can filter and compare opportunities quickly.',
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    color: mediumBlue,
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

  Widget _buildStructuredOpportunityCard() {
    return _buildSectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionLabel(
            _isInternship ? 'Internship compensation' : 'Compensation & format',
          ),
          const SizedBox(height: 6),
          Text(
            _isInternship
                ? 'Add structured details so internship cards can show pay, work mode, duration, and deadline cleanly.'
                : 'These fields power compact job cards, detail views, and future filtering without breaking older records.',
            style: GoogleFonts.poppins(
              fontSize: 12,
              color: mediumBlue,
              height: 1.45,
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: _buildField(
                  controller: _salaryMinController,
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
                  hint: 'Salary max',
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  validator: _validateSalaryMax,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: _buildDropdownField<String>(
                  value: _selectedSalaryCurrency,
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
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: _buildDropdownField<String>(
                  value: _selectedEmploymentType,
                  hint: 'Employment type',
                  items: OpportunityMetadata.employmentTypes
                      .map(
                        (type) => DropdownMenuItem<String>(
                          value: type,
                          child: Text(
                            OpportunityMetadata.formatEmploymentType(type) ??
                                _titleCaseLabel(type),
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
          const SizedBox(height: 14),
          _buildDropdownField<bool>(
            value: _isPaid,
            hint: 'Paid status',
            items: const [
              DropdownMenuItem<bool>(value: true, child: Text('Paid')),
              DropdownMenuItem<bool>(value: false, child: Text('Unpaid')),
            ],
            onChanged: (value) {
              setState(() => _isPaid = value);
            },
          ),
          if (_isInternship) ...[
            const SizedBox(height: 14),
            _buildField(
              controller: _durationController,
              hint: 'Duration, e.g. 2 months',
              validator: _validateDuration,
            ),
          ],
          const SizedBox(height: 14),
          _buildField(
            controller: _compensationTextController,
            hint: 'Optional compensation note for detail screens',
            maxLines: 2,
          ),
        ],
      ),
    );
  }

  Widget _buildSectionCard({required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: child,
    );
  }

  Widget _buildSectionLabel(String text) {
    return Text(
      text,
      style: GoogleFonts.poppins(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: strongBlue,
      ),
    );
  }

  Widget _buildField({
    required TextEditingController controller,
    required String hint,
    int maxLines = 1,
    String? Function(String?)? validator,
    VoidCallback? onTap,
    bool readOnly = false,
    Widget? suffixIcon,
    TextInputType? keyboardType,
  }) {
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      validator: validator,
      onTap: onTap,
      readOnly: readOnly,
      keyboardType: keyboardType,
      style: GoogleFonts.poppins(fontSize: 14),
      decoration: _fieldDecoration(hint: hint, suffixIcon: suffixIcon),
    );
  }

  Widget _buildDropdownField<T>({
    required T? value,
    required String hint,
    required List<DropdownMenuItem<T>> items,
    required ValueChanged<T?> onChanged,
  }) {
    return DropdownButtonFormField<T>(
      initialValue: value,
      isExpanded: true,
      items: items,
      onChanged: onChanged,
      style: GoogleFonts.poppins(fontSize: 14, color: Colors.black87),
      icon: const Icon(Icons.keyboard_arrow_down_rounded),
      decoration: _fieldDecoration(hint: hint),
      hint: Text(
        hint,
        style: GoogleFonts.poppins(color: Colors.grey[500], fontSize: 13),
      ),
      dropdownColor: Colors.white,
    );
  }

  InputDecoration _fieldDecoration({required String hint, Widget? suffixIcon}) {
    return InputDecoration(
      hintText: hint,
      hintStyle: GoogleFonts.poppins(color: Colors.grey[500], fontSize: 13),
      suffixIcon: suffixIcon,
      filled: true,
      fillColor: softGray.withValues(alpha: 0.45),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: Colors.grey.shade200),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: _typeColor, width: 1.4),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: Colors.red),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: Colors.red, width: 1.4),
      ),
    );
  }

  Widget _buildStatusChip({
    required String label,
    required String value,
    required String subtitle,
  }) {
    final isSelected = _selectedStatus == value;
    final chipColor = value == 'open' ? Colors.green : Colors.grey;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => setState(() => _selectedStatus = value),
        borderRadius: BorderRadius.circular(18),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: isSelected
                ? chipColor.withValues(alpha: 0.12)
                : softGray.withValues(alpha: 0.45),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: isSelected ? chipColor : Colors.grey.shade300,
              width: isSelected ? 1.4 : 1,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: GoogleFonts.poppins(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: isSelected ? chipColor : mediumBlue,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: GoogleFonts.poppins(
                  fontSize: 11,
                  color: isSelected
                      ? chipColor.withValues(alpha: 0.85)
                      : Colors.grey.shade600,
                ),
              ),
            ],
          ),
        ),
      ),
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

  String? _validateRequirements(String? value) {
    final text = value?.trim() ?? '';
    if (text.isEmpty) {
      return _selectedType == OpportunityType.sponsoring
          ? 'Eligibility details are required'
          : 'Requirements are required';
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
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('You must be logged in to continue')),
      );
      return;
    }

    final deadlineDate =
        _applicationDeadline ??
        OpportunityMetadata.parseDateTimeLike(_deadlineController.text);
    final structuredData = _buildStructuredPayload();
    final data = {
      'title': _titleController.text.trim(),
      'description': _descriptionController.text.trim(),
      'type': _selectedType,
      'location': _locationController.text.trim(),
      'requirements': _requirementsController.text.trim(),
      'deadline': deadlineDate == null
          ? _deadlineController.text.trim()
          : OpportunityMetadata.formatDateForStorage(deadlineDate),
      'applicationDeadline': deadlineDate == null
          ? null
          : OpportunityMetadata.normalizeDateToEndOfDay(deadlineDate),
      'companyId': user.uid,
      'companyName': user.companyName ?? user.fullName,
      'companyLogo': user.logo ?? '',
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
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error)));
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          _isEditMode
              ? 'Opportunity updated successfully'
              : '${OpportunityType.label(_selectedType)} published successfully',
        ),
        backgroundColor: Colors.green,
      ),
    );
    Navigator.pop(context);
  }

  Map<String, dynamic> _buildStructuredPayload() {
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
    };
  }

  num? _parseOptionalNumber(String rawValue) {
    return OpportunityMetadata.parseNullableNum(rawValue);
  }

  void _applyTypeDefaults(String type) {
    if (!OpportunityMetadata.usesStructuredFields(type)) {
      return;
    }

    _selectedSalaryCurrency ??= OpportunityMetadata.supportedCurrencies.first;

    if (type == OpportunityType.internship) {
      _selectedEmploymentType ??= 'internship';
      return;
    }

    if (_selectedEmploymentType == 'internship') {
      _selectedEmploymentType = null;
    }
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
