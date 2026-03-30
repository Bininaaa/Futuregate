import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/company_provider.dart';

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

  String _selectedType = 'job';
  String _selectedStatus = 'open';
  bool _isLoading = false;
  bool _isEditMode = false;

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
      _deadlineController.text = opp.deadline;
      _selectedType = opp.type;
      _selectedStatus = opp.status;
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
              fontWeight: FontWeight.w600, color: strongBlue),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: strongBlue),
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: vibrantOrange))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildField(
                      label: 'Title',
                      controller: _titleController,
                      hint: 'e.g. Junior Flutter Developer',
                      validator: (v) =>
                          (v == null || v.isEmpty) ? 'Title is required' : null,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Type',
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: strongBlue,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        _buildTypeChip('Job', 'job'),
                        const SizedBox(width: 10),
                        _buildTypeChip('Internship', 'internship'),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Status',
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: strongBlue,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        _buildStatusChip('Open', 'open'),
                        const SizedBox(width: 10),
                        _buildStatusChip('Closed', 'closed'),
                      ],
                    ),
                    const SizedBox(height: 16),
                    _buildField(
                      label: 'Description',
                      controller: _descriptionController,
                      hint: 'Describe the role and responsibilities...',
                      maxLines: 5,
                      validator: (v) => (v == null || v.isEmpty)
                          ? 'Description is required'
                          : null,
                    ),
                    const SizedBox(height: 16),
                    _buildField(
                      label: 'Location',
                      controller: _locationController,
                      hint: 'e.g. Algiers, Algeria',
                      validator: (v) => (v == null || v.isEmpty)
                          ? 'Location is required'
                          : null,
                    ),
                    const SizedBox(height: 16),
                    _buildField(
                      label: 'Requirements',
                      controller: _requirementsController,
                      hint: 'Skills and qualifications needed...',
                      maxLines: 3,
                    ),
                    const SizedBox(height: 16),
                    _buildField(
                      label: 'Deadline',
                      controller: _deadlineController,
                      hint: 'e.g. 2026-06-30',
                      validator: (v) => (v == null || v.isEmpty)
                          ? 'Deadline is required'
                          : null,
                      onTap: _pickDate,
                      readOnly: true,
                    ),
                    const SizedBox(height: 30),
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _submit,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: vibrantOrange,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          elevation: 0,
                        ),
                        child: Text(
                          _isEditMode ? 'Save Changes' : 'Publish',
                          style: GoogleFonts.poppins(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildField({
    required String label,
    required TextEditingController controller,
    String? hint,
    int maxLines = 1,
    String? Function(String?)? validator,
    VoidCallback? onTap,
    bool readOnly = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.poppins(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: strongBlue,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          maxLines: maxLines,
          validator: validator,
          onTap: onTap,
          readOnly: readOnly,
          style: GoogleFonts.poppins(fontSize: 14),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: GoogleFonts.poppins(color: Colors.grey[400]),
            filled: true,
            fillColor: Colors.white,
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide.none,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide(color: Colors.grey.shade200),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: vibrantOrange),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: Colors.red),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTypeChip(String label, String value) {
    final isSelected = _selectedType == value;
    return GestureDetector(
      onTap: () => setState(() => _selectedType = value),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? vibrantOrange : Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSelected ? vibrantOrange : Colors.grey.shade300,
          ),
        ),
        child: Text(
          label,
          style: GoogleFonts.poppins(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: isSelected ? Colors.white : mediumBlue,
          ),
        ),
      ),
    );
  }

  Widget _buildStatusChip(String label, String value) {
    final isSelected = _selectedStatus == value;
    final chipColor = value == 'open' ? Colors.green : Colors.grey;
    return GestureDetector(
      onTap: () => setState(() => _selectedStatus = value),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? chipColor : Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSelected ? chipColor : Colors.grey.shade300,
          ),
        ),
        child: Text(
          label,
          style: GoogleFonts.poppins(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: isSelected ? Colors.white : mediumBlue,
          ),
        ),
      ),
    );
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now().add(const Duration(days: 30)),
      firstDate: DateTime.now(),
      lastDate: DateTime(2030),
    );
    if (picked != null) {
      _deadlineController.text =
          '${picked.year}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}';
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    final user = context.read<AuthProvider>().userModel;
    final provider = context.read<CompanyProvider>();

    if (user == null) {
      setState(() => _isLoading = false);
      return;
    }

    final data = {
      'title': _titleController.text.trim(),
      'description': _descriptionController.text.trim(),
      'type': _selectedType,
      'location': _locationController.text.trim(),
      'requirements': _requirementsController.text.trim(),
      'deadline': _deadlineController.text.trim(),
      'companyId': user.uid,
      'companyName': user.companyName ?? user.fullName,
      'companyLogo': user.logo ?? '',
      'status': _selectedStatus,
    };

    String? error;

    if (_isEditMode) {
      error = await provider.updateOpportunity(widget.opportunityId!, data);
    } else {
      error = await provider.createOpportunity(data);
    }

    if (!mounted) return;

    setState(() => _isLoading = false);

    if (error != null) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(error)));
    } else {
      Navigator.pop(context);
    }
  }
}
