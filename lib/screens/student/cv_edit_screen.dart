import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../providers/auth_provider.dart';
import '../../providers/cv_provider.dart';

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
  final _skillsController = TextEditingController();
  final _languagesController = TextEditingController();

  List<Map<String, dynamic>> _education = [];
  List<Map<String, dynamic>> _experience = [];

  bool _initialized = false;

  static const Color _strongBlue = Color(0xFF004E98);
  static const Color _vibrantOrange = Color(0xFFFF6700);
  static const Color _softGray = Color(0xFFEBEBEB);

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
        _skillsController.text = cv.skills.join(', ');
        _languagesController.text = cv.languages.join(', ');
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
    _skillsController.dispose();
    _languagesController.dispose();
    super.dispose();
  }

  InputDecoration _inputDecoration({
    required String label,
    String? hint,
    IconData? prefixIcon,
  }) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      prefixIcon: prefixIcon != null
          ? Icon(prefixIcon, size: 20, color: _strongBlue.withValues(alpha: 0.5))
          : null,
      labelStyle: GoogleFonts.poppins(
          fontSize: 13, color: _strongBlue.withValues(alpha: 0.7)),
      hintStyle: GoogleFonts.poppins(fontSize: 12, color: Colors.grey[400]),
      filled: true,
      fillColor: Colors.white,
      contentPadding:
          const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.grey[300]!),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.grey[300]!),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: _strongBlue, width: 1.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Colors.red),
      ),
    );
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    final uid = context.read<AuthProvider>().userModel?.uid;
    if (uid == null) return;

    final skills = _skillsController.text
        .split(',')
        .map((s) => s.trim())
        .where((s) => s.isNotEmpty)
        .toList();

    final languages = _languagesController.text
        .split(',')
        .map((s) => s.trim())
        .where((s) => s.isNotEmpty)
        .toList();

    final error = await context.read<CvProvider>().saveCv(
          studentId: uid,
          fullName: _fullNameController.text.trim(),
          email: _emailController.text.trim(),
          phone: _phoneController.text.trim(),
          address: _addressController.text.trim(),
          summary: _summaryController.text.trim(),
          education: _education,
          experience: _experience,
          skills: skills,
          languages: languages,
        );

    if (!mounted) return;

    if (error == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.check_circle, color: Colors.white, size: 18),
              const SizedBox(width: 8),
              Text('CV saved successfully',
                  style: GoogleFonts.poppins(fontSize: 13)),
            ],
          ),
          backgroundColor: Colors.green[600],
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );

      final cv = context.read<CvProvider>().cv;
      if (cv != null && cv.templateId.trim().isEmpty && mounted) {
        final shouldChoose = await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            title: Text('Choose a Template?',
                style: GoogleFonts.poppins(
                    fontWeight: FontWeight.w600, color: _strongBlue)),
            content: Text(
              'Your CV content has been saved. Choose a template to preview and export your CV as a PDF.',
              style: GoogleFonts.poppins(fontSize: 14, color: Colors.grey[600]),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: Text('Later',
                    style: GoogleFonts.poppins(color: Colors.grey)),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(ctx, true),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _vibrantOrange,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                ),
                child: Text('Choose Template',
                    style: GoogleFonts.poppins(fontWeight: FontWeight.w500)),
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
          content: Text(error, style: GoogleFonts.poppins(fontSize: 13)),
          backgroundColor: Colors.red[600],
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
    }
  }

  // ── Education CRUD ────────────────────────────────────────────────────

  void _addOrEditEducation({int? editIndex}) {
    final isEdit = editIndex != null;
    final degreeCtrl = TextEditingController(
        text: isEdit ? (_education[editIndex]['degree'] ?? '') : '');
    final institutionCtrl = TextEditingController(
        text: isEdit ? (_education[editIndex]['institution'] ?? '') : '');
    final yearCtrl = TextEditingController(
        text: isEdit ? (_education[editIndex]['year'] ?? '') : '');

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => Padding(
        padding: EdgeInsets.fromLTRB(
            20, 20, 20, MediaQuery.of(ctx).viewInsets.bottom + 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2)),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              isEdit ? 'Edit Education' : 'Add Education',
              style: GoogleFonts.poppins(
                  fontSize: 18, fontWeight: FontWeight.w600, color: _strongBlue),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: degreeCtrl,
              decoration: _inputDecoration(
                  label: 'Degree *', prefixIcon: Icons.school_outlined),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: institutionCtrl,
              decoration: _inputDecoration(
                  label: 'Institution', prefixIcon: Icons.business_outlined),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: yearCtrl,
              decoration: _inputDecoration(
                  label: 'Year', prefixIcon: Icons.calendar_today_outlined),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
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
                style: ElevatedButton.styleFrom(
                  backgroundColor: _strongBlue,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                child: Text(isEdit ? 'Update' : 'Add',
                    style: GoogleFonts.poppins(
                        fontSize: 15, fontWeight: FontWeight.w600)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Experience CRUD ───────────────────────────────────────────────────

  void _addOrEditExperience({int? editIndex}) {
    final isEdit = editIndex != null;
    final positionCtrl = TextEditingController(
        text: isEdit ? (_experience[editIndex]['position'] ?? '') : '');
    final companyCtrl = TextEditingController(
        text: isEdit ? (_experience[editIndex]['company'] ?? '') : '');
    final durationCtrl = TextEditingController(
        text: isEdit ? (_experience[editIndex]['duration'] ?? '') : '');

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => Padding(
        padding: EdgeInsets.fromLTRB(
            20, 20, 20, MediaQuery.of(ctx).viewInsets.bottom + 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2)),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              isEdit ? 'Edit Experience' : 'Add Experience',
              style: GoogleFonts.poppins(
                  fontSize: 18, fontWeight: FontWeight.w600, color: _strongBlue),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: positionCtrl,
              decoration: _inputDecoration(
                  label: 'Position *', prefixIcon: Icons.work_outline),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: companyCtrl,
              decoration: _inputDecoration(
                  label: 'Company', prefixIcon: Icons.business_outlined),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: durationCtrl,
              decoration: _inputDecoration(
                  label: 'Duration',
                  hint: 'e.g. Jan 2023 — Present',
                  prefixIcon: Icons.date_range_outlined),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
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
                style: ElevatedButton.styleFrom(
                  backgroundColor: _strongBlue,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                child: Text(isEdit ? 'Update' : 'Add',
                    style: GoogleFonts.poppins(
                        fontSize: 15, fontWeight: FontWeight.w600)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Build ─────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final cvProvider = context.watch<CvProvider>();

    return Scaffold(
      backgroundColor: _softGray,
      appBar: AppBar(
        title: Text('Edit CV',
            style: GoogleFonts.poppins(
                fontWeight: FontWeight.w600, color: _strongBlue)),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: _strongBlue),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // ── Personal Information ──
            _sectionHeader(
                title: 'Personal Information', icon: Icons.person_outline),
            const SizedBox(height: 10),
            _card(
              child: Column(
                children: [
                  TextFormField(
                    controller: _fullNameController,
                    style: GoogleFonts.poppins(fontSize: 14),
                    decoration: _inputDecoration(
                        label: 'Full Name *',
                        prefixIcon: Icons.badge_outlined),
                    validator: (v) =>
                        v == null || v.trim().isEmpty ? 'Required' : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _emailController,
                    style: GoogleFonts.poppins(fontSize: 14),
                    keyboardType: TextInputType.emailAddress,
                    decoration: _inputDecoration(
                        label: 'Email *',
                        prefixIcon: Icons.email_outlined),
                    validator: (v) =>
                        v == null || v.trim().isEmpty ? 'Required' : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _phoneController,
                    style: GoogleFonts.poppins(fontSize: 14),
                    keyboardType: TextInputType.phone,
                    decoration: _inputDecoration(
                        label: 'Phone', prefixIcon: Icons.phone_outlined),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _addressController,
                    style: GoogleFonts.poppins(fontSize: 14),
                    decoration: _inputDecoration(
                        label: 'Address',
                        prefixIcon: Icons.location_on_outlined),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // ── Professional Summary ──
            _sectionHeader(
                title: 'Professional Summary', icon: Icons.article_outlined),
            const SizedBox(height: 10),
            _card(
              child: TextFormField(
                controller: _summaryController,
                style: GoogleFonts.poppins(fontSize: 14),
                maxLines: 5,
                decoration: _inputDecoration(
                  label: 'Write a brief summary of your profile',
                ),
              ),
            ),
            const SizedBox(height: 20),

            // ── Education ──
            _sectionHeader(
              title: 'Education',
              icon: Icons.school_outlined,
              trailing: _addButton(onTap: () => _addOrEditEducation()),
            ),
            const SizedBox(height: 10),
            if (_education.isEmpty)
              _emptyState('No education added yet', Icons.school_outlined)
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
            const SizedBox(height: 20),

            // ── Experience ──
            _sectionHeader(
              title: 'Experience',
              icon: Icons.work_outline,
              trailing: _addButton(onTap: () => _addOrEditExperience()),
            ),
            const SizedBox(height: 10),
            if (_experience.isEmpty)
              _emptyState('No experience added yet', Icons.work_outline)
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
            const SizedBox(height: 20),

            // ── Skills ──
            _sectionHeader(
                title: 'Skills', icon: Icons.psychology_outlined),
            const SizedBox(height: 10),
            _card(
              child: TextFormField(
                controller: _skillsController,
                style: GoogleFonts.poppins(fontSize: 14),
                decoration: _inputDecoration(
                  label: 'Skills',
                  hint: 'Flutter, Python, Firebase',
                  prefixIcon: Icons.auto_awesome_outlined,
                ),
              ),
            ),
            const SizedBox(height: 6),
            Padding(
              padding: const EdgeInsets.only(left: 4),
              child: Text('Separate skills with commas',
                  style: GoogleFonts.poppins(
                      fontSize: 11, color: Colors.grey[500])),
            ),
            const SizedBox(height: 20),

            // ── Languages ──
            _sectionHeader(
                title: 'Languages', icon: Icons.translate_outlined),
            const SizedBox(height: 10),
            _card(
              child: TextFormField(
                controller: _languagesController,
                style: GoogleFonts.poppins(fontSize: 14),
                decoration: _inputDecoration(
                  label: 'Languages',
                  hint: 'Arabic, French, English',
                  prefixIcon: Icons.language_outlined,
                ),
              ),
            ),
            const SizedBox(height: 6),
            Padding(
              padding: const EdgeInsets.only(left: 4),
              child: Text('Separate languages with commas',
                  style: GoogleFonts.poppins(
                      fontSize: 11, color: Colors.grey[500])),
            ),
            const SizedBox(height: 32),

            // ── Save Button ──
            cvProvider.isLoading
                ? const Center(
                    child: Padding(
                      padding: EdgeInsets.symmetric(vertical: 10),
                      child: CircularProgressIndicator(),
                    ),
                  )
                : SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _save,
                      icon: const Icon(Icons.save_outlined),
                      label: Text('Save CV',
                          style: GoogleFonts.poppins(
                              fontSize: 16, fontWeight: FontWeight.w600)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _vibrantOrange,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14)),
                        elevation: 0,
                      ),
                    ),
                  ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  // ── Shared widgets ──────────────────────────────────────────────────

  Widget _sectionHeader({
    required String title,
    required IconData icon,
    Widget? trailing,
  }) {
    return Row(
      children: [
        Icon(icon, size: 20, color: _strongBlue),
        const SizedBox(width: 8),
        Expanded(
          child: Text(title,
              style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: _strongBlue)),
        ),
        ?trailing,
      ],
    );
  }

  Widget _addButton({required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: _strongBlue.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.add, size: 16, color: _strongBlue),
            const SizedBox(width: 4),
            Text('Add',
                style: GoogleFonts.poppins(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: _strongBlue)),
          ],
        ),
      ),
    );
  }

  Widget _card({required Widget child}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: child,
    );
  }

  Widget _itemCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required VoidCallback onEdit,
    required VoidCallback onDelete,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: _strongBlue.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, size: 18, color: _strongBlue),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: GoogleFonts.poppins(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: _strongBlue)),
                if (subtitle.trim().isNotEmpty)
                  Text(subtitle,
                      style: GoogleFonts.poppins(
                          fontSize: 11,
                          color: _strongBlue.withValues(alpha: 0.55))),
              ],
            ),
          ),
          GestureDetector(
            onTap: onEdit,
            child: Padding(
              padding: const EdgeInsets.all(6),
              child: Icon(Icons.edit_outlined,
                  size: 18, color: _strongBlue.withValues(alpha: 0.5)),
            ),
          ),
          GestureDetector(
            onTap: onDelete,
            child: Padding(
              padding: const EdgeInsets.all(6),
              child: Icon(Icons.delete_outline,
                  size: 18, color: Colors.red[300]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _emptyState(String text, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
            color: Colors.grey[200]!, style: BorderStyle.solid),
      ),
      child: Column(
        children: [
          Icon(icon, size: 28, color: Colors.grey[300]),
          const SizedBox(height: 6),
          Text(text,
              style: GoogleFonts.poppins(
                  fontSize: 12, color: Colors.grey[400])),
        ],
      ),
    );
  }
}
