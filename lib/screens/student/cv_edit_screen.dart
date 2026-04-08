import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/auth_provider.dart';
import '../../providers/cv_provider.dart';
import '../../screens/settings/settings_flow_theme.dart';
import '../../screens/settings/settings_flow_widgets.dart';

class CvEditScreen extends StatefulWidget {
  const CvEditScreen({super.key});

  @override
  State<CvEditScreen> createState() => _CvEditScreenState();
}

class _CvEditScreenState extends State<CvEditScreen> {
  final _formKey = GlobalKey<FormState>();
  final _fullNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _addressController = TextEditingController();
  final _summaryController = TextEditingController();
  final _skillInputController = TextEditingController();
  final _languageInputController = TextEditingController();

  List<Map<String, dynamic>> _education = [];
  List<Map<String, dynamic>> _experience = [];
  List<String> _skills = [];
  List<String> _languages = [];

  bool _initialized = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_initialized) {
      final cv = context.read<CvProvider>().cv;
      final user = context.read<AuthProvider>().userModel;

      if (cv != null) {
        _fullNameController.text = cv.fullName;
        _emailController.text = cv.email;
        _phoneController.text = cv.phone;
        _addressController.text = cv.address;
        _summaryController.text = cv.summary;
        _skills = List.from(cv.skills);
        _languages = List.from(cv.languages);
        _education = List.from(cv.education);
        _experience = List.from(cv.experience);
      } else if (user != null) {
        _fullNameController.text = user.fullName;
        _emailController.text = user.email;
        _phoneController.text = user.phone;
      }

      _initialized = true;
    }
  }

  @override
  void dispose() {
    _fullNameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _summaryController.dispose();
    _skillInputController.dispose();
    _languageInputController.dispose();
    super.dispose();
  }

  InputDecoration _inputDecoration({
    required String label,
    String? hint,
    IconData? prefixIcon,
    Widget? suffixIcon,
  }) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      prefixIcon: prefixIcon != null
          ? Icon(prefixIcon, size: 20, color: SettingsFlowPalette.textSecondary)
          : null,
      suffixIcon: suffixIcon,
      labelStyle: SettingsFlowTheme.caption(),
      hintStyle: SettingsFlowTheme.caption(
        SettingsFlowPalette.textSecondary.withValues(alpha: 0.5),
      ),
      filled: true,
      fillColor: SettingsFlowPalette.background,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: SettingsFlowPalette.border),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: SettingsFlowPalette.border),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(
          color: SettingsFlowPalette.primary,
          width: 1.5,
        ),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: SettingsFlowPalette.error),
      ),
    );
  }

  // ── Save ────────────────────────────────────────────────────────────────

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    final uid = context.read<AuthProvider>().userModel?.uid;
    if (uid == null) return;

    final error = await context.read<CvProvider>().saveCv(
      studentId: uid,
      fullName: _fullNameController.text.trim(),
      email: _emailController.text.trim(),
      phone: _phoneController.text.trim(),
      address: _addressController.text.trim(),
      summary: _summaryController.text.trim(),
      education: _education,
      experience: _experience,
      skills: _skills,
      languages: _languages,
    );

    if (!mounted) return;

    if (error == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'CV saved',
            style: SettingsFlowTheme.body(Colors.white),
          ),
          backgroundColor: SettingsFlowPalette.success,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: SettingsFlowTheme.radius(12),
          ),
        ),
      );

      final cv = context.read<CvProvider>().cv;
      if (cv != null && cv.templateId.trim().isEmpty && mounted) {
        final shouldChoose = await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: SettingsFlowTheme.radius(20),
            ),
            title: Text(
              'Choose a Template?',
              style: SettingsFlowTheme.sectionTitle(),
            ),
            content: Text(
              'Your CV is saved. Pick a template to preview and export as PDF.',
              style: SettingsFlowTheme.body(SettingsFlowPalette.textSecondary),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: Text(
                  'Later',
                  style: SettingsFlowTheme.body(
                    SettingsFlowPalette.textSecondary,
                  ),
                ),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(ctx, true),
                style: ElevatedButton.styleFrom(
                  backgroundColor: SettingsFlowPalette.primary,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: SettingsFlowTheme.radius(12),
                  ),
                ),
                child: Text(
                  'Choose',
                  style: SettingsFlowTheme.body(Colors.white),
                ),
              ),
            ],
          ),
        );

        if (!mounted) return;
        Navigator.pop(context, shouldChoose == true ? 'pick_template' : null);
      } else {
        Navigator.pop(context);
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error, style: SettingsFlowTheme.body(Colors.white)),
          backgroundColor: SettingsFlowPalette.error,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: SettingsFlowTheme.radius(12),
          ),
        ),
      );
    }
  }

  // ── Skills / Languages ──────────────────────────────────────────────────

  void _addSkill() {
    final text = _skillInputController.text.trim();
    if (text.isEmpty) return;
    setState(() {
      for (final item
          in text.split(',').map((s) => s.trim()).where((s) => s.isNotEmpty)) {
        if (!_skills.contains(item)) _skills.add(item);
      }
      _skillInputController.clear();
    });
  }

  void _addLanguage() {
    final text = _languageInputController.text.trim();
    if (text.isEmpty) return;
    setState(() {
      for (final item
          in text.split(',').map((s) => s.trim()).where((s) => s.isNotEmpty)) {
        if (!_languages.contains(item)) _languages.add(item);
      }
      _languageInputController.clear();
    });
  }

  // ── Education CRUD ──────────────────────────────────────────────────────

  void _addOrEditEducation({int? editIndex}) {
    final isEdit = editIndex != null;
    final degreeCtrl = TextEditingController(
      text: isEdit ? (_education[editIndex]['degree'] ?? '') : '',
    );
    final institutionCtrl = TextEditingController(
      text: isEdit ? (_education[editIndex]['institution'] ?? '') : '',
    );
    final yearCtrl = TextEditingController(
      text: isEdit ? (_education[editIndex]['year'] ?? '') : '',
    );

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: SettingsFlowPalette.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => Padding(
        padding: EdgeInsets.fromLTRB(
          20,
          16,
          20,
          MediaQuery.of(ctx).viewInsets.bottom + 20,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: SettingsFlowPalette.border,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              isEdit ? 'Edit Education' : 'Add Education',
              style: SettingsFlowTheme.sectionTitle(),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: degreeCtrl,
              style: SettingsFlowTheme.body(),
              decoration: _inputDecoration(
                label: 'Degree',
                prefixIcon: Icons.school_outlined,
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: institutionCtrl,
              style: SettingsFlowTheme.body(),
              decoration: _inputDecoration(
                label: 'Institution',
                prefixIcon: Icons.business_outlined,
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: yearCtrl,
              style: SettingsFlowTheme.body(),
              decoration: _inputDecoration(
                label: 'Year',
                prefixIcon: Icons.calendar_today_outlined,
              ),
            ),
            const SizedBox(height: 20),
            SettingsPrimaryButton(
              label: isEdit ? 'Update' : 'Add',
              onPressed: () {
                if (degreeCtrl.text.trim().isEmpty) return;
                setState(() {
                  final entry = {
                    'degree': degreeCtrl.text.trim(),
                    'institution': institutionCtrl.text.trim(),
                    'year': yearCtrl.text.trim(),
                  };
                  if (isEdit) {
                    _education[editIndex] = entry;
                  } else {
                    _education.add(entry);
                  }
                });
                Navigator.pop(ctx);
              },
            ),
          ],
        ),
      ),
    );
  }

  // ── Experience CRUD ─────────────────────────────────────────────────────

  void _addOrEditExperience({int? editIndex}) {
    final isEdit = editIndex != null;
    final positionCtrl = TextEditingController(
      text: isEdit ? (_experience[editIndex]['position'] ?? '') : '',
    );
    final companyCtrl = TextEditingController(
      text: isEdit ? (_experience[editIndex]['company'] ?? '') : '',
    );
    final durationCtrl = TextEditingController(
      text: isEdit ? (_experience[editIndex]['duration'] ?? '') : '',
    );

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: SettingsFlowPalette.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => Padding(
        padding: EdgeInsets.fromLTRB(
          20,
          16,
          20,
          MediaQuery.of(ctx).viewInsets.bottom + 20,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: SettingsFlowPalette.border,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              isEdit ? 'Edit Experience' : 'Add Experience',
              style: SettingsFlowTheme.sectionTitle(),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: positionCtrl,
              style: SettingsFlowTheme.body(),
              decoration: _inputDecoration(
                label: 'Position',
                prefixIcon: Icons.work_outline,
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: companyCtrl,
              style: SettingsFlowTheme.body(),
              decoration: _inputDecoration(
                label: 'Company',
                prefixIcon: Icons.business_outlined,
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: durationCtrl,
              style: SettingsFlowTheme.body(),
              decoration: _inputDecoration(
                label: 'Duration',
                hint: 'e.g. Jan 2023 — Present',
                prefixIcon: Icons.date_range_outlined,
              ),
            ),
            const SizedBox(height: 20),
            SettingsPrimaryButton(
              label: isEdit ? 'Update' : 'Add',
              onPressed: () {
                if (positionCtrl.text.trim().isEmpty) return;
                setState(() {
                  final entry = {
                    'position': positionCtrl.text.trim(),
                    'company': companyCtrl.text.trim(),
                    'duration': durationCtrl.text.trim(),
                  };
                  if (isEdit) {
                    _experience[editIndex] = entry;
                  } else {
                    _experience.add(entry);
                  }
                });
                Navigator.pop(ctx);
              },
            ),
          ],
        ),
      ),
    );
  }

  // ── Build ───────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final cvProvider = context.watch<CvProvider>();

    return SettingsPageScaffold(
      title: 'Edit CV',
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Personal Information ──
            const SettingsSectionHeading(title: 'Personal Information'),
            const SizedBox(height: 10),
            SettingsPanel(
              child: Column(
                children: [
                  TextFormField(
                    controller: _fullNameController,
                    style: SettingsFlowTheme.body(),
                    decoration: _inputDecoration(
                      label: 'Full Name',
                      prefixIcon: Icons.badge_outlined,
                    ),
                    validator: (v) =>
                        v == null || v.trim().isEmpty ? 'Required' : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _emailController,
                    style: SettingsFlowTheme.body(),
                    keyboardType: TextInputType.emailAddress,
                    decoration: _inputDecoration(
                      label: 'Email',
                      prefixIcon: Icons.email_outlined,
                    ),
                    validator: (v) =>
                        v == null || v.trim().isEmpty ? 'Required' : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _phoneController,
                    style: SettingsFlowTheme.body(),
                    keyboardType: TextInputType.phone,
                    decoration: _inputDecoration(
                      label: 'Phone',
                      prefixIcon: Icons.phone_outlined,
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _addressController,
                    style: SettingsFlowTheme.body(),
                    decoration: _inputDecoration(
                      label: 'Address',
                      prefixIcon: Icons.location_on_outlined,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // ── Professional Summary ──
            const SettingsSectionHeading(title: 'Professional Summary'),
            const SizedBox(height: 10),
            SettingsPanel(
              child: TextFormField(
                controller: _summaryController,
                style: SettingsFlowTheme.body(),
                maxLines: 4,
                decoration: _inputDecoration(
                  label: 'A brief summary of your profile',
                ),
              ),
            ),

            const SizedBox(height: 24),

            // ── Education ──
            SettingsSectionHeading(
              title: 'Education',
              trailing: _addChip(onTap: () => _addOrEditEducation()),
            ),
            const SizedBox(height: 10),
            if (_education.isEmpty)
              _emptyState('Add your education', Icons.school_outlined)
            else
              ..._education.asMap().entries.map((entry) {
                final i = entry.key;
                final edu = entry.value;
                return _itemCard(
                  title: edu['degree'] ?? '',
                  subtitle:
                      '${edu['institution'] ?? ''}${(edu['year'] ?? '').toString().isNotEmpty ? '  •  ${edu['year']}' : ''}',
                  icon: Icons.school_outlined,
                  onEdit: () => _addOrEditEducation(editIndex: i),
                  onDelete: () => setState(() => _education.removeAt(i)),
                );
              }),

            const SizedBox(height: 24),

            // ── Experience ──
            SettingsSectionHeading(
              title: 'Experience',
              trailing: _addChip(onTap: () => _addOrEditExperience()),
            ),
            const SizedBox(height: 10),
            if (_experience.isEmpty)
              _emptyState('Add your experience', Icons.work_outline)
            else
              ..._experience.asMap().entries.map((entry) {
                final i = entry.key;
                final exp = entry.value;
                return _itemCard(
                  title: exp['position'] ?? '',
                  subtitle:
                      '${exp['company'] ?? ''}${(exp['duration'] ?? '').toString().isNotEmpty ? '  •  ${exp['duration']}' : ''}',
                  icon: Icons.work_outline,
                  onEdit: () => _addOrEditExperience(editIndex: i),
                  onDelete: () => setState(() => _experience.removeAt(i)),
                );
              }),

            const SizedBox(height: 24),

            // ── Skills ──
            const SettingsSectionHeading(title: 'Skills'),
            const SizedBox(height: 10),
            SettingsPanel(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (_skills.isNotEmpty) ...[
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: _skills.asMap().entries.map((entry) {
                        return _chip(
                          entry.value,
                          () => setState(() => _skills.removeAt(entry.key)),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 12),
                  ],
                  TextFormField(
                    controller: _skillInputController,
                    style: SettingsFlowTheme.body(),
                    decoration: _inputDecoration(
                      label: 'Add a skill',
                      hint: 'Type and press Enter',
                      prefixIcon: Icons.auto_awesome_outlined,
                      suffixIcon: IconButton(
                        icon: const Icon(
                          Icons.add_circle_outline,
                          color: SettingsFlowPalette.primary,
                        ),
                        onPressed: _addSkill,
                      ),
                    ),
                    onFieldSubmitted: (_) => _addSkill(),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // ── Languages ──
            const SettingsSectionHeading(title: 'Languages'),
            const SizedBox(height: 10),
            SettingsPanel(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (_languages.isNotEmpty) ...[
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: _languages.asMap().entries.map((entry) {
                        return _chip(
                          entry.value,
                          () => setState(() => _languages.removeAt(entry.key)),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 12),
                  ],
                  TextFormField(
                    controller: _languageInputController,
                    style: SettingsFlowTheme.body(),
                    decoration: _inputDecoration(
                      label: 'Add a language',
                      hint: 'Type and press Enter',
                      prefixIcon: Icons.translate_outlined,
                      suffixIcon: IconButton(
                        icon: const Icon(
                          Icons.add_circle_outline,
                          color: SettingsFlowPalette.primary,
                        ),
                        onPressed: _addLanguage,
                      ),
                    ),
                    onFieldSubmitted: (_) => _addLanguage(),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 32),

            // ── Save ──
            cvProvider.isLoading
                ? const Center(
                    child: Padding(
                      padding: EdgeInsets.symmetric(vertical: 10),
                      child: CircularProgressIndicator(
                        color: SettingsFlowPalette.primary,
                      ),
                    ),
                  )
                : SettingsPrimaryButton(
                    label: 'Save CV',
                    icon: Icons.check_rounded,
                    onPressed: _save,
                  ),

            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  // ── Helper Widgets ──────────────────────────────────────────────────────

  Widget _addChip({required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: SettingsFlowPalette.primary.withValues(alpha: 0.08),
          borderRadius: SettingsFlowTheme.radius(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.add_rounded,
              size: 16,
              color: SettingsFlowPalette.primary,
            ),
            const SizedBox(width: 4),
            Text(
              'Add',
              style: SettingsFlowTheme.micro(SettingsFlowPalette.primary),
            ),
          ],
        ),
      ),
    );
  }

  Widget _chip(String label, VoidCallback onDelete) {
    return Container(
      padding: const EdgeInsets.only(left: 12, right: 6, top: 6, bottom: 6),
      decoration: BoxDecoration(
        color: SettingsFlowPalette.primary.withValues(alpha: 0.08),
        borderRadius: SettingsFlowTheme.radius(10),
        border: Border.all(
          color: SettingsFlowPalette.primary.withValues(alpha: 0.15),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: SettingsFlowTheme.caption(SettingsFlowPalette.primary),
          ),
          const SizedBox(width: 4),
          GestureDetector(
            onTap: onDelete,
            child: Icon(
              Icons.close_rounded,
              size: 16,
              color: SettingsFlowPalette.primary.withValues(alpha: 0.5),
            ),
          ),
        ],
      ),
    );
  }

  Widget _itemCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required VoidCallback onEdit,
    required VoidCallback onDelete,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: SettingsPanel(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Row(
          children: [
            SettingsIconBox(icon: icon, color: SettingsFlowPalette.primary),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: SettingsFlowTheme.cardTitle()),
                  if (subtitle.trim().isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 2),
                      child: Text(subtitle, style: SettingsFlowTheme.caption()),
                    ),
                ],
              ),
            ),
            GestureDetector(
              onTap: onEdit,
              child: const Padding(
                padding: EdgeInsets.all(6),
                child: Icon(
                  Icons.edit_outlined,
                  size: 18,
                  color: SettingsFlowPalette.textSecondary,
                ),
              ),
            ),
            GestureDetector(
              onTap: onDelete,
              child: Padding(
                padding: const EdgeInsets.all(6),
                child: Icon(
                  Icons.delete_outline,
                  size: 18,
                  color: SettingsFlowPalette.error.withValues(alpha: 0.6),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _emptyState(String text, IconData icon) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 28),
      decoration: BoxDecoration(
        color: SettingsFlowPalette.surface,
        borderRadius: SettingsFlowTheme.radius(20),
        border: Border.all(color: SettingsFlowPalette.border),
      ),
      child: Column(
        children: [
          Icon(
            icon,
            size: 28,
            color: SettingsFlowPalette.textSecondary.withValues(alpha: 0.35),
          ),
          const SizedBox(height: 8),
          Text(text, style: SettingsFlowTheme.caption()),
        ],
      ),
    );
  }
}
