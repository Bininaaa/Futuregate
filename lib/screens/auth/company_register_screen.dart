import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:file_picker/file_picker.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../utils/document_upload_validator.dart';
import '../../utils/validators.dart';
import '../../widgets/shared/app_feedback.dart';
import '../../widgets/password_strength_indicator.dart';

class CompanyRegisterScreen extends StatefulWidget {
  const CompanyRegisterScreen({super.key});

  @override
  State<CompanyRegisterScreen> createState() => _CompanyRegisterScreenState();
}

class _CompanyRegisterScreenState extends State<CompanyRegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _companyNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _phoneController = TextEditingController();
  final _websiteController = TextEditingController();
  final _sectorController = TextEditingController();
  final _descriptionController = TextEditingController();
  PlatformFile? _commercialRegisterFile;
  String? _commercialRegisterError;

  bool _obscurePassword = true;
  bool _obscureConfirm = true;
  String _passwordText = '';

  static const Color _navyBlue = Color(0xFF004E98);
  static const Color _mediumBlue = Color(0xFF3A6EA5);
  static const Color _accentOrange = Color(0xFFFF8C00);

  @override
  void initState() {
    super.initState();
    _passwordController.addListener(() {
      setState(() => _passwordText = _passwordController.text);
    });
  }

  @override
  void dispose() {
    _companyNameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _phoneController.dispose();
    _websiteController.dispose();
    _sectorController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) return;

    final selectedFile = _commercialRegisterFile;
    final commercialRegisterError = selectedFile == null
        ? 'Upload your commercial register to continue.'
        : DocumentUploadValidator.validateCommercialRegister(
            fileName: selectedFile.name,
            sizeInBytes: selectedFile.size,
          );

    if (commercialRegisterError != null) {
      setState(() => _commercialRegisterError = commercialRegisterError);
      return;
    }

    final authProvider = context.read<AuthProvider>();
    final error = await authProvider.registerCompany(
      companyName: _companyNameController.text.trim(),
      email: _emailController.text.trim(),
      password: _passwordController.text.trim(),
      commercialRegisterFileName: selectedFile!.name,
      commercialRegisterFilePath: selectedFile.path ?? '',
      commercialRegisterBytes: selectedFile.bytes,
      phone: _phoneController.text.trim(),
      website: _websiteController.text.trim(),
      sector: _sectorController.text.trim(),
      description: _descriptionController.text.trim(),
    );

    if (!mounted) return;
    if (error != null) {
      context.showAppSnackBar(
        error,
        title: 'Registration unavailable',
        type: AppFeedbackType.error,
      );
    } else {
      Navigator.of(context).popUntil((route) => route.isFirst);
    }
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

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFFE8EFF7), Color(0xFFF0F4F8), Color(0xFFF8FAFC)],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            child: Column(
              children: [
                _buildTopBar(),
                _buildBrandingArea(),
                _buildFormCard(authProvider),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTopBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          Container(
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.9),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.08),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: IconButton(
              icon: const Icon(Icons.arrow_back, color: _navyBlue),
              onPressed: () => Navigator.pop(context),
            ),
          ),
          const Expanded(
            child: Text(
              'AvenirDZ',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: _navyBlue,
              ),
            ),
          ),
          const SizedBox(width: 48),
        ],
      ),
    );
  }

  Widget _buildBrandingArea() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 20),
      child: Column(
        children: [
          Container(
            width: 70,
            height: 70,
            decoration: BoxDecoration(
              gradient: const LinearGradient(colors: [_navyBlue, _mediumBlue]),
              borderRadius: BorderRadius.circular(18),
              boxShadow: [
                BoxShadow(
                  color: _navyBlue.withValues(alpha: 0.3),
                  blurRadius: 14,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: const Icon(
              Icons.business_center_rounded,
              size: 36,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 14),
          const Text(
            'Company Registration',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: _navyBlue,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Register your organization to post\nopportunities and connect with talent.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 13,
              color: Colors.grey.shade600,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFormCard(AuthProvider authProvider) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 28),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 20,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildSectionLabel('Company Information'),
            const SizedBox(height: 14),
            _buildTextField(
              controller: _companyNameController,
              label: 'Company Name',
              hint: 'Ex: TechCorp Algeria',
              icon: Icons.business_outlined,
              validator: (v) => (v == null || v.trim().isEmpty)
                  ? 'Company name is required'
                  : null,
            ),
            const SizedBox(height: 14),
            _buildTextField(
              controller: _sectorController,
              label: 'Industry / Sector (optional)',
              hint: 'Ex: Technology, Healthcare, Finance...',
              icon: Icons.category_outlined,
            ),
            const SizedBox(height: 14),
            _buildTextField(
              controller: _descriptionController,
              label: 'Company Description (optional)',
              hint: 'Brief description of your organization...',
              icon: Icons.description_outlined,
              maxLines: 3,
            ),
            const SizedBox(height: 18),
            _buildCommercialRegisterSection(),
            const SizedBox(height: 24),
            _buildSectionLabel('Account Details'),
            const SizedBox(height: 14),
            _buildTextField(
              controller: _emailController,
              label: 'Business Email',
              hint: 'contact@company.com',
              icon: Icons.email_outlined,
              keyboardType: TextInputType.emailAddress,
              validator: Validators.validateEmail,
            ),
            const SizedBox(height: 14),
            _buildTextField(
              controller: _passwordController,
              label: 'Password',
              hint: '\u2022\u2022\u2022\u2022\u2022\u2022\u2022\u2022',
              icon: Icons.lock_outline,
              obscureText: _obscurePassword,
              suffixIcon: IconButton(
                icon: Icon(
                  _obscurePassword
                      ? Icons.visibility_off_outlined
                      : Icons.visibility_outlined,
                  size: 20,
                  color: Colors.grey,
                ),
                onPressed: () =>
                    setState(() => _obscurePassword = !_obscurePassword),
              ),
              validator: Validators.validatePassword,
            ),
            PasswordStrengthIndicator(password: _passwordText),
            const SizedBox(height: 14),
            _buildTextField(
              controller: _confirmPasswordController,
              label: 'Confirm Password',
              hint: '\u2022\u2022\u2022\u2022\u2022\u2022\u2022\u2022',
              icon: Icons.lock_outline,
              obscureText: _obscureConfirm,
              suffixIcon: IconButton(
                icon: Icon(
                  _obscureConfirm
                      ? Icons.visibility_off_outlined
                      : Icons.visibility_outlined,
                  size: 20,
                  color: Colors.grey,
                ),
                onPressed: () =>
                    setState(() => _obscureConfirm = !_obscureConfirm),
              ),
              validator: (value) => Validators.validateConfirmPassword(
                value,
                _passwordController.text,
              ),
            ),
            const SizedBox(height: 24),
            _buildSectionLabel('Contact (optional)'),
            const SizedBox(height: 14),
            _buildTextField(
              controller: _phoneController,
              label: 'Phone Number',
              hint: '+213 xxx xxx xxx',
              icon: Icons.phone_outlined,
              keyboardType: TextInputType.phone,
            ),
            const SizedBox(height: 14),
            _buildTextField(
              controller: _websiteController,
              label: 'Website',
              hint: 'https://www.company.com',
              icon: Icons.language_outlined,
              keyboardType: TextInputType.url,
            ),
            const SizedBox(height: 28),
            _buildRegisterButton(authProvider),
            const SizedBox(height: 16),
            _buildLoginLink(),
            const SizedBox(height: 12),
            _buildTermsText(),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionLabel(String text) {
    return Row(
      children: [
        Container(
          width: 4,
          height: 18,
          decoration: BoxDecoration(
            color: _navyBlue,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 10),
        Text(
          text,
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w700,
            color: _navyBlue,
          ),
        ),
      ],
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
    bool obscureText = false,
    Widget? suffixIcon,
    String? Function(String?)? validator,
    int maxLines = 1,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: _navyBlue,
          ),
        ),
        const SizedBox(height: 6),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          obscureText: obscureText,
          validator: validator,
          maxLines: maxLines,
          style: const TextStyle(fontSize: 14),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 13),
            prefixIcon: Icon(icon, size: 20, color: _mediumBlue),
            suffixIcon: suffixIcon,
            filled: true,
            fillColor: const Color(0xFFF8FAFC),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 14,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide(color: Colors.grey.shade200),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide(color: Colors.grey.shade200),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: _navyBlue, width: 1.5),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: Colors.red, width: 1),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: Colors.red, width: 1.5),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCommercialRegisterSection() {
    final selectedFile = _commercialRegisterFile;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: (_commercialRegisterError == null ? _mediumBlue : Colors.red)
              .withValues(alpha: 0.22),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: _navyBlue.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.verified_outlined,
                  color: _navyBlue,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Commercial Register',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: _navyBlue,
                      ),
                    ),
                    SizedBox(height: 2),
                    Text(
                      'Commercial Register',
                      style: TextStyle(fontSize: 12, color: _mediumBlue),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            'Required for company account creation. Accepted formats: PDF, JPG, PNG. Maximum size: 10 MB.',
            style: TextStyle(
              fontSize: 12,
              height: 1.5,
              color: Colors.grey.shade700,
            ),
          ),
          const SizedBox(height: 14),
          if (selectedFile != null) ...[
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: _mediumBlue.withValues(alpha: 0.16)),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.insert_drive_file_outlined,
                    color: _navyBlue,
                    size: 20,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          selectedFile.name,
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: _navyBlue,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${(selectedFile.size / (1024 * 1024)).toStringAsFixed(2)} MB',
                          style: TextStyle(
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
          ] else
            OutlinedButton.icon(
              onPressed: _pickCommercialRegister,
              icon: const Icon(Icons.upload_file_outlined),
              label: const Text('Upload Commercial Register'),
              style: OutlinedButton.styleFrom(
                foregroundColor: _navyBlue,
                side: BorderSide(color: _navyBlue.withValues(alpha: 0.3)),
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 14,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
            ),
          if (_commercialRegisterError != null) ...[
            const SizedBox(height: 10),
            AppFieldErrorText(
              message: _commercialRegisterError!,
              accentColor: _accentOrange,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildRegisterButton(AuthProvider authProvider) {
    return SizedBox(
      height: 52,
      child: authProvider.isLoading
          ? const Center(child: CircularProgressIndicator(color: _navyBlue))
          : ElevatedButton(
              onPressed: _register,
              style: ElevatedButton.styleFrom(
                backgroundColor: _navyBlue,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
                elevation: 3,
                shadowColor: _navyBlue.withValues(alpha: 0.4),
              ),
              child: const Text(
                'Register Company',
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.5,
                ),
              ),
            ),
    );
  }

  Widget _buildLoginLink() {
    return Center(
      child: RichText(
        text: TextSpan(
          text: 'Already have an account? ',
          style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
          children: [
            TextSpan(
              text: 'Log in',
              style: const TextStyle(
                color: _accentOrange,
                fontWeight: FontWeight.bold,
              ),
              recognizer: TapGestureRecognizer()
                ..onTap = () =>
                    Navigator.of(context).popUntil((route) => route.isFirst),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTermsText() {
    return Center(
      child: RichText(
        textAlign: TextAlign.center,
        text: TextSpan(
          style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
          children: const [
            TextSpan(text: 'By registering, you agree to our '),
            TextSpan(
              text: 'Terms of Use',
              style: TextStyle(
                decoration: TextDecoration.underline,
                fontWeight: FontWeight.w500,
              ),
            ),
            TextSpan(text: ' and our '),
            TextSpan(
              text: 'Privacy Policy',
              style: TextStyle(
                decoration: TextDecoration.underline,
                fontWeight: FontWeight.w500,
              ),
            ),
            TextSpan(text: '.'),
          ],
        ),
      ),
    );
  }
}
