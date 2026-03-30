import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../models/user_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/company_provider.dart';
import '../../services/document_access_service.dart';
import '../../utils/document_upload_validator.dart';
import '../../widgets/profile_avatar.dart';
import '../settings/settings_screen.dart';

class CompanyProfileScreen extends StatelessWidget {
  const CompanyProfileScreen({super.key});

  static const Color vibrantOrange = Color(0xFFFF6700);
  static const Color strongBlue = Color(0xFF004E98);
  static const Color mediumBlue = Color(0xFF3A6EA5);
  static const Color softGray = Color(0xFFEBEBEB);

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().userModel;

    if (user == null) {
      return const Scaffold(body: Center(child: Text('Not logged in')));
    }

    return Scaffold(
      backgroundColor: softGray,
      appBar: AppBar(
        title: Text(
          'Company Profile',
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.w600,
            color: strongBlue,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined, color: mediumBlue),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const SettingsScreen()),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.edit_outlined, color: vibrantOrange),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const _EditProfileScreen()),
              );
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            ProfileAvatar(user: user, radius: 45),
            const SizedBox(height: 14),
            Text(
              user.companyName ?? user.fullName,
              style: GoogleFonts.poppins(
                fontSize: 22,
                fontWeight: FontWeight.w700,
                color: strongBlue,
              ),
              textAlign: TextAlign.center,
            ),
            if ((user.sector ?? '').isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(
                user.sector!,
                style: GoogleFonts.poppins(fontSize: 14, color: mediumBlue),
              ),
            ],
            const SizedBox(height: 24),
            _buildInfoCard(
              'Description',
              user.description ?? 'Not set',
              Icons.info_outline,
            ),
            const SizedBox(height: 12),
            _buildInfoCard('Email', user.email, Icons.email_outlined),
            const SizedBox(height: 12),
            _buildInfoCard(
              'Phone',
              user.phone.isNotEmpty ? user.phone : 'Not set',
              Icons.phone_outlined,
            ),
            const SizedBox(height: 12),
            _buildInfoCard(
              'Location',
              user.location.isNotEmpty ? user.location : 'Not set',
              Icons.location_on_outlined,
            ),
            const SizedBox(height: 12),
            _buildInfoCard(
              'Website',
              user.website ?? 'Not set',
              Icons.language_outlined,
            ),
            const SizedBox(height: 12),
            _buildCommercialRegisterCard(context, user),
            const SizedBox(height: 30),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton.icon(
                onPressed: () => context.read<AuthProvider>().logout(),
                icon: const Icon(Icons.logout, size: 20),
                label: Text(
                  'Logout',
                  style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  elevation: 0,
                ),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoCard(String label, String value, IconData icon) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: strongBlue.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: strongBlue, size: 20),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: GoogleFonts.poppins(
                    fontSize: 11,
                    color: mediumBlue,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    color: strongBlue,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCommercialRegisterCard(BuildContext context, UserModel user) {
    final hasDocument = user.hasCommercialRegister;
    final uploadedAt = user.commercialRegisterUploadedAt;
    final uploadedAtLabel = uploadedAt == null
        ? 'Not available'
        : DateFormat('MMM d, yyyy').format(uploadedAt.toDate());

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: strongBlue.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.verified_user_outlined,
                  color: strongBlue,
                  size: 20,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'سجل تجاري',
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: strongBlue,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Commercial Register',
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        color: mediumBlue,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (hasDocument) ...[
            Text(
              user.commercialRegisterFileName.isNotEmpty
                  ? user.commercialRegisterFileName
                  : 'Document uploaded',
              style: GoogleFonts.poppins(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: strongBlue,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Uploaded: $uploadedAtLabel',
              style: GoogleFonts.poppins(fontSize: 12, color: mediumBlue),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () =>
                        _openCommercialRegister(context, companyId: user.uid),
                    icon: const Icon(Icons.visibility_outlined, size: 18),
                    label: const Text('View'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: strongBlue,
                      side: BorderSide(
                        color: strongBlue.withValues(alpha: 0.24),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _openCommercialRegister(
                      context,
                      companyId: user.uid,
                      download: true,
                    ),
                    icon: const Icon(Icons.download_outlined, size: 18),
                    label: const Text('Download'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: vibrantOrange,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ] else
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.orange.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: Colors.orange.withValues(alpha: 0.22),
                ),
              ),
              child: Text(
                'No سجل تجاري uploaded yet. Please add it from Edit Profile to keep your company profile complete.',
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  height: 1.5,
                  color: Colors.orange.shade800,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Future<void> _openCommercialRegister(
    BuildContext context, {
    required String companyId,
    bool download = false,
  }) async {
    final messenger = ScaffoldMessenger.of(context);

    try {
      final document = await DocumentAccessService()
          .getCompanyCommercialRegister(companyId: companyId);
      final url = download ? document.downloadUrl : document.viewUrl;
      final uri = Uri.tryParse(url);

      if (uri == null) {
        throw Exception('File unavailable.');
      }

      final launched = await launchUrl(
        uri,
        mode: LaunchMode.platformDefault,
        webOnlyWindowName: '_blank',
      );
      if (!launched) {
        messenger.showSnackBar(
          const SnackBar(content: Text('Could not open the document.')),
        );
      }
    } catch (e) {
      messenger.showSnackBar(SnackBar(content: Text(_documentErrorMessage(e))));
    }
  }

  String _documentErrorMessage(Object error) {
    final message = error.toString();
    if (message.contains('permission') || message.contains('403')) {
      return 'Permission denied while opening the document.';
    }
    if (message.contains('404') || message.contains('not found')) {
      return 'The requested document is no longer available.';
    }

    return 'Could not open the document right now.';
  }
}

class _EditProfileScreen extends StatefulWidget {
  const _EditProfileScreen();

  @override
  State<_EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<_EditProfileScreen> {
  static const Color vibrantOrange = Color(0xFFFF6700);
  static const Color strongBlue = Color(0xFF004E98);
  static const Color softGray = Color(0xFFEBEBEB);

  final _formKey = GlobalKey<FormState>();
  final _companyNameController = TextEditingController();
  final _sectorController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _phoneController = TextEditingController();
  final _locationController = TextEditingController();
  final _websiteController = TextEditingController();
  PlatformFile? _commercialRegisterFile;
  String? _commercialRegisterError;

  bool _saving = false;
  bool _uploadingLogo = false;

  @override
  void initState() {
    super.initState();
    final user = context.read<AuthProvider>().userModel;
    if (user != null) {
      _companyNameController.text = user.companyName ?? '';
      _sectorController.text = user.sector ?? '';
      _descriptionController.text = user.description ?? '';
      _phoneController.text = user.phone;
      _locationController.text = user.location;
      _websiteController.text = user.website ?? '';
    }
  }

  @override
  void dispose() {
    _companyNameController.dispose();
    _sectorController.dispose();
    _descriptionController.dispose();
    _phoneController.dispose();
    _locationController.dispose();
    _websiteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: softGray,
      appBar: AppBar(
        title: Text(
          'Edit Profile',
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.w600,
            color: strongBlue,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: strongBlue),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              _buildField('Company Name', _companyNameController),
              const SizedBox(height: 14),
              _buildField('Sector', _sectorController),
              const SizedBox(height: 14),
              _buildField('Description', _descriptionController, maxLines: 4),
              const SizedBox(height: 14),
              _buildField('Phone', _phoneController),
              const SizedBox(height: 14),
              _buildField('Location', _locationController),
              const SizedBox(height: 14),
              _buildField('Website', _websiteController),
              const SizedBox(height: 18),
              _buildLogoUploadSection(),
              const SizedBox(height: 18),
              _buildCommercialRegisterSection(),
              const SizedBox(height: 28),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _saving ? null : _save,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: vibrantOrange,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 0,
                  ),
                  child: _saving
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : Text(
                          'Save Changes',
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

  Widget _buildField(
    String label,
    TextEditingController controller, {
    int maxLines = 1,
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
        const SizedBox(height: 6),
        TextFormField(
          controller: controller,
          maxLines: maxLines,
          style: GoogleFonts.poppins(fontSize: 14),
          decoration: InputDecoration(
            filled: true,
            fillColor: Colors.white,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 14,
            ),
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
          ),
        ),
      ],
    );
  }

  Widget _buildLogoUploadSection() {
    final user = context.watch<AuthProvider>().userModel;
    final hasLogo = user != null && (user.logo ?? '').isNotEmpty;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: strongBlue.withValues(alpha: 0.18)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Company Logo / Picture',
            style: GoogleFonts.poppins(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: strongBlue,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Upload a logo or company photo. JPG, PNG or WebP. Max 5 MB.',
            style: GoogleFonts.poppins(
              fontSize: 12,
              color: Colors.grey.shade700,
            ),
          ),
          const SizedBox(height: 12),
          Center(child: ProfileAvatar(user: user, radius: 36)),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: _uploadingLogo ? null : _pickAndUploadLogo,
              icon: _uploadingLogo
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.upload_outlined),
              label: Text(
                _uploadingLogo
                    ? 'Uploading...'
                    : hasLogo
                    ? 'Replace Logo'
                    : 'Upload Logo',
                style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
              ),
              style: OutlinedButton.styleFrom(
                foregroundColor: strongBlue,
                side: BorderSide(color: strongBlue.withValues(alpha: 0.2)),
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),
          if (hasLogo) ...[
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              child: TextButton.icon(
                onPressed: _uploadingLogo ? null : _removeLogo,
                icon: const Icon(Icons.delete_outline, size: 18),
                label: Text(
                  'Remove Logo',
                  style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
                ),
                style: TextButton.styleFrom(foregroundColor: Colors.red),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _pickAndUploadLogo() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['jpg', 'jpeg', 'png', 'webp'],
      withData: true,
    );

    if (result == null || result.files.isEmpty) return;

    final file = result.files.single;
    if (file.size > 5 * 1024 * 1024) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Image must be smaller than 5 MB')),
      );
      return;
    }

    if (!mounted) return;
    final authProvider = context.read<AuthProvider>();
    final user = authProvider.userModel;
    if (user == null) return;

    setState(() => _uploadingLogo = true);

    final companyProvider = context.read<CompanyProvider>();
    final messenger = ScaffoldMessenger.of(context);

    try {
      final error = await companyProvider.uploadCompanyLogo(
        uid: user.uid,
        fileName: file.name,
        filePath: file.path ?? '',
        fileBytes: file.bytes,
      );

      if (!mounted) return;
      if (error != null) {
        messenger.showSnackBar(SnackBar(content: Text(error)));
        return;
      }

      await authProvider.loadCurrentUser();
    } catch (e) {
      if (!mounted) return;
      messenger.showSnackBar(
        SnackBar(content: Text('Failed to upload logo: $e')),
      );
    } finally {
      if (mounted) setState(() => _uploadingLogo = false);
    }
  }

  Future<void> _removeLogo() async {
    final authProvider = context.read<AuthProvider>();
    final companyProvider = context.read<CompanyProvider>();
    final user = authProvider.userModel;
    if (user == null || _uploadingLogo) return;

    setState(() => _uploadingLogo = true);

    try {
      final error = await companyProvider.removeCompanyLogo(user.uid);

      if (!mounted) return;

      if (error != null) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(error)));
        return;
      }

      await authProvider.loadCurrentUser();
    } finally {
      if (mounted) {
        setState(() => _uploadingLogo = false);
      }
    }
  }

  Widget _buildCommercialRegisterSection() {
    final currentUser = context.read<AuthProvider>().userModel;
    final selectedFile = _commercialRegisterFile;
    final hasExistingDocument = currentUser?.hasCommercialRegister ?? false;
    final uploadedAt = currentUser?.commercialRegisterUploadedAt;
    final uploadedAtLabel = uploadedAt == null
        ? 'Not available'
        : DateFormat('MMM d, yyyy').format(uploadedAt.toDate());

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: (_commercialRegisterError == null ? strongBlue : Colors.red)
              .withValues(alpha: 0.18),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'سجل تجاري',
            style: GoogleFonts.poppins(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: strongBlue,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Commercial Register',
            style: GoogleFonts.poppins(
              fontSize: 12,
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Upload a current company registration document in PDF, JPG, or PNG format. Maximum size: 10 MB.',
            style: GoogleFonts.poppins(
              fontSize: 12,
              height: 1.5,
              color: Colors.grey.shade700,
            ),
          ),
          const SizedBox(height: 12),
          if (selectedFile != null) ...[
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: softGray,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.insert_drive_file_outlined,
                    color: strongBlue,
                    size: 20,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          selectedFile.name,
                          style: GoogleFonts.poppins(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: strongBlue,
                          ),
                        ),
                        Text(
                          '${(selectedFile.size / (1024 * 1024)).toStringAsFixed(2)} MB',
                          style: GoogleFonts.poppins(
                            fontSize: 11,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  TextButton(
                    onPressed: _pickCommercialRegister,
                    child: const Text('Replace'),
                  ),
                ],
              ),
            ),
          ] else if (hasExistingDocument) ...[
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: softGray,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    currentUser!.commercialRegisterFileName.isNotEmpty
                        ? currentUser.commercialRegisterFileName
                        : 'Document uploaded',
                    style: GoogleFonts.poppins(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: strongBlue,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Uploaded: $uploadedAtLabel',
                    style: GoogleFonts.poppins(
                      fontSize: 11,
                      color: Colors.grey.shade600,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () => _openCommercialRegister(
                            companyId: currentUser.uid,
                          ),
                          icon: const Icon(Icons.visibility_outlined, size: 18),
                          label: const Text('View'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: strongBlue,
                            side: BorderSide(
                              color: strongBlue.withValues(alpha: 0.2),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: _pickCommercialRegister,
                          icon: const Icon(
                            Icons.upload_file_outlined,
                            size: 18,
                          ),
                          label: const Text('Replace'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: vibrantOrange,
                            side: BorderSide(
                              color: vibrantOrange.withValues(alpha: 0.2),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ] else
            OutlinedButton.icon(
              onPressed: _pickCommercialRegister,
              icon: const Icon(Icons.upload_file_outlined),
              label: const Text('Upload سجل تجاري'),
              style: OutlinedButton.styleFrom(
                foregroundColor: strongBlue,
                side: BorderSide(color: strongBlue.withValues(alpha: 0.2)),
              ),
            ),
          if (_commercialRegisterError != null) ...[
            const SizedBox(height: 10),
            Text(
              _commercialRegisterError!,
              style: GoogleFonts.poppins(
                fontSize: 12,
                color: Colors.red,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _pickCommercialRegister() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf', 'png', 'jpg', 'jpeg'],
      withData: true,
    );

    if (result == null || result.files.isEmpty) {
      return;
    }

    final file = result.files.single;
    final validationError = DocumentUploadValidator.validateCommercialRegister(
      fileName: file.name,
      sizeInBytes: file.size,
    );

    setState(() {
      _commercialRegisterFile = file;
      _commercialRegisterError = validationError;
    });
  }

  Future<void> _save() async {
    setState(() => _saving = true);

    final user = context.read<AuthProvider>().userModel;
    if (user == null) {
      setState(() => _saving = false);
      return;
    }

    final selectedFile = _commercialRegisterFile;
    final commercialRegisterError = selectedFile != null
        ? DocumentUploadValidator.validateCommercialRegister(
            fileName: selectedFile.name,
            sizeInBytes: selectedFile.size,
          )
        : (!user.hasCommercialRegister
              ? 'سجل تجاري is required for company profiles.'
              : null);

    if (commercialRegisterError != null) {
      setState(() {
        _saving = false;
        _commercialRegisterError = commercialRegisterError;
      });
      return;
    }

    final data = {
      'companyName': _companyNameController.text.trim(),
      'sector': _sectorController.text.trim(),
      'description': _descriptionController.text.trim(),
      'phone': _phoneController.text.trim(),
      'location': _locationController.text.trim(),
      'website': _websiteController.text.trim(),
    };

    final error = await context.read<CompanyProvider>().updateProfile(
      user.uid,
      data,
      commercialRegisterFilePath: selectedFile?.path ?? '',
      commercialRegisterFileName: selectedFile?.name ?? '',
      commercialRegisterBytes: selectedFile?.bytes,
    );

    if (!mounted) return;

    setState(() => _saving = false);

    if (error != null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error)));
    } else {
      await context.read<AuthProvider>().loadCurrentUser();
      if (!mounted) return;
      Navigator.pop(context);
    }
  }

  Future<void> _openCommercialRegister({
    required String companyId,
    bool download = false,
  }) async {
    final messenger = ScaffoldMessenger.of(context);

    try {
      final document = await DocumentAccessService()
          .getCompanyCommercialRegister(companyId: companyId);
      final uri = Uri.tryParse(
        download ? document.downloadUrl : document.viewUrl,
      );
      if (uri == null) {
        throw Exception('File unavailable.');
      }

      final launched = await launchUrl(
        uri,
        mode: LaunchMode.platformDefault,
        webOnlyWindowName: '_blank',
      );
      if (!launched && mounted) {
        messenger.showSnackBar(
          const SnackBar(content: Text('Could not open the document.')),
        );
      }
    } catch (e) {
      if (!mounted) return;
      messenger.showSnackBar(SnackBar(content: Text(_documentErrorMessage(e))));
    }
  }

  String _documentErrorMessage(Object error) {
    final message = error.toString();
    if (message.contains('permission') || message.contains('403')) {
      return 'Permission denied while opening the document.';
    }
    if (message.contains('404') || message.contains('not found')) {
      return 'The requested document is no longer available.';
    }

    return 'Could not open the document right now.';
  }
}
