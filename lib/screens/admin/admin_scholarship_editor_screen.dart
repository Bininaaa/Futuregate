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
    final l10n = AppLocalizations.of(context)!;
    return AdminEditorScaffold(
      title: _isEditing
          ? l10n.adminScholarshipEditTitle
          : l10n.adminScholarshipPublishTitle,
      submitLabel: _isEditing
          ? l10n.adminScholarshipSaveLabel
          : l10n.adminScholarshipPublishLabel,
      icon: Icons.card_giftcard_rounded,
      accentColor: Colors.pink,
      subtitle: l10n.adminScholarshipScaffoldSubtitle,
      isSubmitting: _isSubmitting,
      onSubmit: _submit,
      child: Form(
        key: _formKey,
        autovalidateMode: AutovalidateMode.onUserInteraction,
        child: Column(
          children: [
            AdminEditorSection(
              title: l10n.uiPublishingLabel,
              subtitle: l10n.adminScholarshipPublishingSubtitle,
              child: AdminEditorToggleCard(
                value: _featured,
                onChanged: (value) => setState(() => _featured = value),
                title: l10n.adminScholarshipFeatureTitle,
                subtitle: l10n.adminScholarshipFeatureSubtitle,
              ),
            ),
            const SizedBox(height: 16),
            AdminEditorSection(
              title: l10n.uiBasicInformation,
              subtitle: l10n.adminScholarshipBasicInfoSubtitle,
              child: Column(
                children: [
                  AdminEditorField(
                    controller: _titleController,
                    label: l10n.adminScholarshipTitleLabel,
                    hint: l10n.adminScholarshipTitleHint,
                    validator: adminRequiredMin(
                      l10n.adminScholarshipTitleValidatorLabel,
                      min: 4,
                    ),
                  ),
                  const SizedBox(height: 14),
                  AdminEditorField(
                    controller: _providerController,
                    label: l10n.uiProvider,
                    hint: l10n.adminScholarshipProviderHint,
                    validator: adminRequiredMin(
                      l10n.adminScholarshipProviderValidatorLabel,
                      min: 2,
                    ),
                  ),
                  const SizedBox(height: 14),
                  AdminEditorDropdown<String>(
                    value: _originalLanguage,
                    label: AppLocalizations.of(
                      context,
                    )!.originalLanguageFieldLabel,
                    items: [
                      DropdownMenuItem(
                        value: 'fr',
                        child: Text(
                          AppLocalizations.of(context)!.languageFrench,
                        ),
                      ),
                      DropdownMenuItem(
                        value: 'en',
                        child: Text(
                          AppLocalizations.of(context)!.languageEnglish,
                        ),
                      ),
                      DropdownMenuItem(
                        value: 'ar',
                        child: Text(
                          AppLocalizations.of(context)!.languageArabic,
                        ),
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
              title: l10n.descriptionSectionTitle,
              child: Column(
                children: [
                  AdminEditorField(
                    controller: _descriptionController,
                    label: '',
                    hint: l10n.adminScholarshipDescriptionHint,
                    maxLines: 5,
                    minLength: 60,
                    helperText: l10n.adminScholarshipDescriptionHelper,
                    validator: adminRequiredMin(
                      l10n.adminScholarshipDescriptionValidatorLabel,
                      min: 60,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            AdminEditorSection(
              title: l10n.adminScholarshipEligibilityTitle,
              child: Column(
                children: [
                  AdminEditorListField(
                    label: '',
                    hint: l10n.adminScholarshipEligibilityHint,
                    values: _eligibilityItems,
                    onChanged: (items) =>
                        setState(() => _eligibilityItems = items),
                    listController: _eligibilityListController,
                    validator: _validateEligibilityItems,
                    emptyText: l10n.adminScholarshipEligibilityEmpty,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            AdminEditorSection(
              title: l10n.logisticsTitle,
              subtitle: l10n.adminScholarshipLogisticsSubtitle,
              child: Column(
                children: [
                  AdminEditorField(
                    controller: _amountController,
                    label: l10n.uiAmount,
                    hint: l10n.adminScholarshipAmountHint,
                    keyboardType: TextInputType.number,
                    validator: _validateAmount,
                  ),
                  const SizedBox(height: 14),
                  AdminEditorField(
                    controller: _deadlineController,
                    label: l10n.uiDeadline,
                    hint: l10n.adminScholarshipDeadlineHint,
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
                          label: l10n.uiCountry,
                          hint: l10n.adminScholarshipCountryHint,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: AdminEditorField(
                          controller: _cityController,
                          label: l10n.uiCity,
                          hint: l10n.adminScholarshipCityHint,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  AdminEditorField(
                    controller: _locationController,
                    label: l10n.adminScholarshipLocationLabelField,
                    hint: l10n.adminScholarshipLocationHint,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            AdminEditorSection(
              title: l10n.uiAdditionalInformation,
              subtitle: l10n.adminScholarshipAdditionalInfoSubtitle,
              child: Column(
                children: [
                  AdminEditorField(
                    controller: _linkController,
                    label: l10n.adminScholarshipApplicationLinkLabel,
                    hint: l10n.adminScholarshipApplicationLinkHint,
                  ),
                  const SizedBox(height: 14),
                  AdminEditorField(
                    controller: _fundingTypeController,
                    label: l10n.adminScholarshipFundingTypeLabel,
                    hint: l10n.adminScholarshipFundingTypeHint,
                  ),
                  const SizedBox(height: 14),
                  AdminEditorField(
                    controller: _categoryController,
                    label: l10n.uiCategory,
                    hint: l10n.adminScholarshipCategoryHint,
                  ),
                  const SizedBox(height: 14),
                  AdminEditorField(
                    controller: _levelController,
                    label: l10n.uiLevel,
                    hint: l10n.adminScholarshipLevelHint,
                  ),
                  const SizedBox(height: 14),
                  AdminEditorField(
                    controller: _imageUrlController,
                    label: l10n.adminScholarshipImageUrlLabel,
                    hint: l10n.adminScholarshipImageUrlHint,
                  ),
                  const SizedBox(height: 14),
                  AdminEditorField(
                    controller: _tagsController,
                    label: l10n.uiTags,
                    hint: l10n.adminScholarshipTagsHint,
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
      helpText: AppLocalizations.of(context)!.adminScholarshipDeadlinePickerHelp,
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
        title: _isEditing
            ? l10n.updateUnavailableTitle
            : l10n.publishUnavailableTitle,
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
    if (parsed == null || parsed < 0) {
      return AppLocalizations.of(context)!.adminScholarshipAmountValidator;
    }
    return null;
  }

  String? _validateEligibilityItems(List<String> items) {
    if (items.where((item) => item.trim().isNotEmpty).isEmpty) {
      return AppLocalizations.of(context)!.adminScholarshipEligibilityValidator;
    }
    return null;
  }

  String? _validateDeadline(String? value) {
    final text = value?.trim() ?? '';
    final l10n = AppLocalizations.of(context)!;
    if (text.isEmpty) return l10n.adminScholarshipDeadlineRequired;
    final parsed = OpportunityMetadata.parseDateTimeLike(text);
    return parsed == null ? l10n.adminScholarshipDeadlineInvalid : null;
  }
}
