import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../l10n/generated/app_localizations.dart';
import '../../providers/admin_provider.dart';
import '../../providers/auth_provider.dart';
import '../../theme/locale_controller.dart';
import '../../utils/content_language.dart';
import '../../utils/opportunity_metadata.dart';
import '../../widgets/shared/app_content_system.dart';
import '../../widgets/shared/app_feedback.dart';
import 'admin_editor_widgets.dart';

class AdminScholarshipEditorScreen extends StatefulWidget {
  final Map<String, dynamic>? initialScholarship;

  const AdminScholarshipEditorScreen({super.key, this.initialScholarship});

  @override
  State<AdminScholarshipEditorScreen> createState() =>
      _AdminScholarshipEditorScreenState();
}

class _AdminScholarshipEditorScreenState
    extends State<AdminScholarshipEditorScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _providerController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _amountController = TextEditingController();
  final _deadlineController = TextEditingController();
  final _linkController = TextEditingController();
  final _countryController = TextEditingController();
  final _cityController = TextEditingController();
  final _locationController = TextEditingController();
  final _imageUrlController = TextEditingController();
  final _fundingTypeController = TextEditingController();
  final _categoryController = TextEditingController();
  final _levelController = TextEditingController();
  final _tagsController = TextEditingController();
  final _eligibilityListController = AppEditableListController();
  List<String> _eligibilityItems = <String>[];

  DateTime? _deadline;
  bool _featured = false;
  bool _isSubmitting = false;
  String _originalLanguage = 'fr';

  bool get _isEditing => widget.initialScholarship != null;

  @override
  void initState() {
    super.initState();
    _originalLanguage = _defaultOriginalLanguage();
    final scholarship = widget.initialScholarship;
    if (scholarship == null) return;

    _titleController.text = scholarship['title']?.toString() ?? '';
    _providerController.text = scholarship['provider']?.toString() ?? '';
    _descriptionController.text = scholarship['description']?.toString() ?? '';
    _eligibilityItems = OpportunityMetadata.stringListFromValue(
      scholarship['eligibilityItems'] ?? scholarship['eligibility_items'],
      maxItems: 12,
    );
    if (_eligibilityItems.isEmpty) {
      _eligibilityItems = OpportunityMetadata.stringListFromValue(
        scholarship['eligibility'],
        maxItems: 12,
      );
    }
    _amountController.text = scholarship['amount']?.toString() ?? '';
    _deadlineController.text = scholarship['deadline']?.toString() ?? '';
    _linkController.text = scholarship['link']?.toString() ?? '';
    _countryController.text = scholarship['country']?.toString() ?? '';
    _cityController.text = scholarship['city']?.toString() ?? '';
    _locationController.text = scholarship['location']?.toString() ?? '';
    _imageUrlController.text = scholarship['imageUrl']?.toString() ?? '';
    _fundingTypeController.text = scholarship['fundingType']?.toString() ?? '';
    _categoryController.text = scholarship['category']?.toString() ?? '';
    _levelController.text = scholarship['level']?.toString() ?? '';
    _tagsController.text = adminJoinList(
      (scholarship['tags'] as List<dynamic>? ?? const <dynamic>[])
          .map((item) => item.toString())
          .toList(growable: false),
    );
    _featured = scholarship['featured'] == true;
    _deadline = OpportunityMetadata.parseDateTimeLike(scholarship['deadline']);
    _originalLanguage = ContentLanguage.normalizeCode(
      scholarship['originalLanguage']?.toString(),
      fallback: _defaultOriginalLanguage(),
    );
  }

  String _defaultOriginalLanguage() {
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
    _titleController.dispose();
    _providerController.dispose();
    _descriptionController.dispose();
    _amountController.dispose();
    _deadlineController.dispose();
    _linkController.dispose();
    _countryController.dispose();
    _cityController.dispose();
    _locationController.dispose();
    _imageUrlController.dispose();
    _fundingTypeController.dispose();
    _categoryController.dispose();
    _levelController.dispose();
    _tagsController.dispose();
    _eligibilityListController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AdminEditorScaffold(
      title: _isEditing ? 'Edit Scholarship' : 'Publish Scholarship',
      submitLabel: _isEditing
          ? 'Save Scholarship Changes'
          : 'Publish Scholarship',
      icon: Icons.card_giftcard_rounded,
      accentColor: Colors.pink,
      subtitle:
          'Curate scholarships in the same app where students discover them, with enough structure for richer cards and more useful filtering.',
      isSubmitting: _isSubmitting,
      onSubmit: _submit,
      child: Form(
        key: _formKey,
        child: Column(
          children: [
            AdminEditorSection(
              title: 'Publishing',
              subtitle:
                  'Featured scholarships get stronger presence in the student discovery flow.',
              child: AdminEditorToggleCard(
                value: _featured,
                onChanged: (value) => setState(() => _featured = value),
                title: 'Feature this scholarship',
                subtitle:
                    'Use this for high-priority or especially strong scholarship opportunities.',
              ),
            ),
            const SizedBox(height: 16),
            AdminEditorSection(
              title: 'Basic Information',
              subtitle:
                  'Start with the core scholarship identity so the opportunity reads clearly across cards and details.',
              child: Column(
                children: [
                  AdminEditorField(
                    controller: _titleController,
                    label: 'Scholarship title',
                    hint: 'e.g. Future Builders Global Scholarship',
                    validator: adminRequiredMin('Title', min: 4),
                  ),
                  const SizedBox(height: 14),
                  AdminEditorField(
                    controller: _providerController,
                    label: 'Provider',
                    hint: 'Who offers this scholarship?',
                    validator: adminRequiredMin('Provider', min: 2),
                  ),
                  const SizedBox(height: 14),
                  AdminEditorDropdown<String>(
                    value: _originalLanguage,
                    label: AppLocalizations.of(context)!.originalLanguageFieldLabel,
                    items: [
                      DropdownMenuItem(
                        value: 'fr',
                        child: Text(AppLocalizations.of(context)!.languageFrench),
                      ),
                      DropdownMenuItem(
                        value: 'en',
                        child: Text(AppLocalizations.of(context)!.languageEnglish),
                      ),
                      DropdownMenuItem(
                        value: 'ar',
                        child: Text(AppLocalizations.of(context)!.languageArabic),
                      ),
                    ],
                    onChanged: (value) {
                      if (value != null) {
                        setState(() => _originalLanguage = value);
                      }
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            AdminEditorSection(
              title: 'Description',
              subtitle:
                  'Explain what the scholarship supports and why it stands out.',
              child: Column(
                children: [
                  AdminEditorField(
                    controller: _descriptionController,
                    label: 'Description',
                    hint: 'Explain the scholarship and what it supports',
                    maxLines: 5,
                    validator: adminRequiredMin('Description', min: 20),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            AdminEditorSection(
              title: 'Requirements And Eligibility',
              subtitle:
                  'Make the eligibility criteria explicit before students click out to apply.',
              child: Column(
                children: [
                  AdminEditorListField(
                    label: 'Eligibility',
                    hint: 'Type one eligibility rule, then press Enter',
                    values: _eligibilityItems,
                    onChanged: (items) =>
                        setState(() => _eligibilityItems = items),
                    listController: _eligibilityListController,
                    validator: _validateEligibilityItems,
                    examples: const <String>[
                      'Open to Master students',
                      'Minimum GPA required',
                      'English language certificate',
                    ],
                    emptyText:
                        'Add who can apply, required documents, or academic conditions.',
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            AdminEditorSection(
              title: 'Logistics',
              subtitle:
                  'Keep the amount, deadline, and destination details in one predictable section.',
              child: Column(
                children: [
                  AdminEditorField(
                    controller: _amountController,
                    label: 'Amount',
                    hint: 'e.g. 250000',
                    keyboardType: TextInputType.number,
                    validator: _validateAmount,
                  ),
                  const SizedBox(height: 14),
                  AdminEditorField(
                    controller: _deadlineController,
                    label: 'Deadline',
                    hint: 'Select a deadline',
                    readOnly: true,
                    suffixIcon: const Icon(Icons.calendar_today_rounded),
                    onTap: _pickDeadline,
                    validator: _validateDeadline,
                  ),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      Expanded(
                        child: AdminEditorField(
                          controller: _countryController,
                          label: 'Country',
                          hint: 'e.g. France',
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: AdminEditorField(
                          controller: _cityController,
                          label: 'City',
                          hint: 'e.g. Paris',
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  AdminEditorField(
                    controller: _locationController,
                    label: 'Location label',
                    hint: 'Fallback location text',
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            AdminEditorSection(
              title: 'Additional Information',
              subtitle:
                  'Use these optional fields to improve discovery, filtering, and outbound application clarity.',
              child: Column(
                children: [
                  AdminEditorField(
                    controller: _linkController,
                    label: 'Application link',
                    hint: 'Optional direct link',
                  ),
                  const SizedBox(height: 14),
                  AdminEditorField(
                    controller: _fundingTypeController,
                    label: 'Funding type',
                    hint: 'e.g. Fully funded, Partial funding',
                  ),
                  const SizedBox(height: 14),
                  AdminEditorField(
                    controller: _categoryController,
                    label: 'Category',
                    hint: 'e.g. Masters, Research, Exchange',
                  ),
                  const SizedBox(height: 14),
                  AdminEditorField(
                    controller: _levelController,
                    label: 'Level',
                    hint: 'e.g. Master, PhD',
                  ),
                  const SizedBox(height: 14),
                  AdminEditorField(
                    controller: _imageUrlController,
                    label: 'Image URL',
                    hint: 'Optional cover image URL',
                  ),
                  const SizedBox(height: 14),
                  AdminEditorField(
                    controller: _tagsController,
                    label: 'Tags',
                    hint: 'Comma-separated tags',
                  ),
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
        _deadline ??
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
      _deadline = normalized;
      _deadlineController.text = OpportunityMetadata.formatDateForStorage(
        normalized,
      );
    });
  }

  Future<void> _submit() async {
    final l10n = AppLocalizations.of(context)!;
    FocusScope.of(context).unfocus();
    _eligibilityListController.commitPendingInput();
    if (!_formKey.currentState!.validate()) return;

    final auth = context.read<AuthProvider>().userModel;
    if (auth == null) return;

    setState(() => _isSubmitting = true);

    final eligibilityText = _eligibilityItems.join('\n');
    final payload = <String, dynamic>{
      'title': _titleController.text.trim(),
      'provider': _providerController.text.trim(),
      'description': _descriptionController.text.trim(),
      'eligibility': eligibilityText,
      'eligibilityItems': _eligibilityItems,
      'amount': _amountController.text.trim(),
      'deadline': _deadline != null
          ? OpportunityMetadata.formatDateForStorage(_deadline!)
          : _deadlineController.text.trim(),
      'link': _linkController.text.trim(),
      'country': _countryController.text.trim(),
      'city': _cityController.text.trim(),
      'location': _locationController.text.trim(),
      'imageUrl': _imageUrlController.text.trim(),
      'fundingType': _fundingTypeController.text.trim(),
      'category': _categoryController.text.trim(),
      'level': _levelController.text.trim(),
      'tags': adminSplitCsv(_tagsController.text),
      'originalLanguage': _originalLanguage,
      'featured': _featured,
      'createdBy': auth.uid,
      'createdByRole': 'admin',
    };

    final provider = context.read<AdminProvider>();
    final error = _isEditing
        ? await provider.updateScholarship(
            widget.initialScholarship!['id'].toString(),
            payload,
          )
        : await provider.createScholarship(payload);

    if (!mounted) return;
    setState(() => _isSubmitting = false);

    if (error != null) {
      context.showAppSnackBar(
        error,
        title: _isEditing ? l10n.updateUnavailableTitle : l10n.publishUnavailableTitle,
        type: AppFeedbackType.error,
      );
      return;
    }

    context.showAppSnackBar(
      _isEditing
          ? l10n.scholarshipUpdatedMessage
          : l10n.scholarshipPublishedMessage,
      type: AppFeedbackType.success,
    );
    Navigator.of(context).pop(true);
  }

  String? _validateAmount(String? value) {
    final parsed = num.tryParse(
      (value ?? '').replaceAll(RegExp(r'[^0-9.\-]'), ''),
    );
    if (parsed == null || parsed < 0) return 'Enter a valid amount';
    return null;
  }

  String? _validateEligibilityItems(List<String> items) {
    if (items.where((item) => item.trim().isNotEmpty).isEmpty) {
      return 'Add at least one eligibility item';
    }
    return null;
  }

  String? _validateDeadline(String? value) {
    final text = value?.trim() ?? '';
    if (text.isEmpty) return 'Deadline is required';
    final parsed = OpportunityMetadata.parseDateTimeLike(text);
    return parsed == null ? 'Use a valid date' : null;
  }
}
