import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:file_picker/file_picker.dart';
import 'package:provider/provider.dart';
import '../../l10n/generated/app_localizations.dart';
import '../../providers/auth_provider.dart';
import '../../utils/document_upload_validator.dart';
import '../../utils/validators.dart';
import '../../widgets/shared/app_feedback.dart';
import '../../widgets/shared/app_logo.dart';
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

    final l10n = AppLocalizations.of(context)!;
    final selectedFile = _commercialRegisterFile;
    final commercialRegisterError = selectedFile == null
        ? l10n.uiUploadCommercialRegisterToContinue
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
        title: l10n.uiRegistrationUnavailable,
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
          const Expanded(child: Center(child: AppLogoClear(height: 32))),
          const SizedBox(width: 48),
        ],
      ),
    );
  }

  Widget _buildBrandingArea() {
    final l10n = AppLocalizations.of(context)!;
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
          Text(
            l10n.uiCompanyRegistration,
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: _navyBlue,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            l10n.uiRegisterCompanySubtitle,
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
    final l10n = AppLocalizations.of(context)!;
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
            _buildSectionLabel(l10n.uiCompanyInformation),
            const SizedBox(height: 14),
            _buildTextField(
              controller: _companyNameController,
              label: l10n.uiCompanyName,
              hint: l10n.uiExTechCorpAlgeria,
              icon: Icons.business_outlined,
              validator: (v) => (v == null || v.trim().isEmpty)
                  ? l10n.uiCompanyNameIsRequired
                  : null,
            ),
            const SizedBox(height: 14),
            _buildTextField(
              controller: _sectorController,
              label: l10n.uiIndustrySectorOptional,
              hint: l10n.uiExTechnologyHealthcareFinance,
              icon: Icons.category_outlined,
            ),
            const SizedBox(height: 14),
            _buildTextField(
              controller: _descriptionController,
              label: l10n.uiCompanyDescriptionOptional,
              hint: l10n.uiBriefDescriptionOfYourOrganization,
              icon: Icons.description_outlined,
              maxLines: 3,
            ),
            const SizedBox(height: 18),
            _buildCommercialRegisterSection(),
            const SizedBox(height: 24),
            _buildSectionLabel(l10n.uiAccountDetails),
            const SizedBox(height: 14),
            _buildTextField(
              controller: _emailController,
              label: l10n.uiBusinessEmail,
              hint: l10n.uiContactEmailHint,
              icon: Icons.email_outlined,
              keyboardType: TextInputType.emailAddress,
              validator: Validators.email(l10n),
            ),
            const SizedBox(height: 14),
            _buildTextField(
              controller: _passwordController,
              label: l10n.uiPassword,
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
              validator: Validators.password(l10n),
            ),
            PasswordStrengthIndicator(password: _passwordText),
            const SizedBox(height: 14),
            _buildTextField(
              controller: _confirmPasswordController,
              label: l10n.uiConfirmPassword,
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
              validator: Validators.confirmPassword(
                l10n,
                _passwordController.text,
              ),
            ),
            const SizedBox(height: 24),
            _buildSectionLabel(l10n.uiContactOptional),
            const SizedBox(height: 14),
            _buildTextField(
              controller: _phoneController,
              label: l10n.uiPhoneNumber,
              hint: l10n.uiPhoneNumberHint,
              icon: Icons.phone_outlined,
              keyboardType: TextInputType.phone,
            ),
            const SizedBox(height: 14),
            _buildTextField(
              controller: _websiteController,
              label: l10n.uiWebsite,
              hint: l10n.uiWebsiteHint,
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
          style: TextStyle(
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
          style: TextStyle(
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
    final l10n = AppLocalizations.of(context)!;
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
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.uiCommercialRegister,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: _navyBlue,
                      ),
                    ),
                    SizedBox(height: 2),
                    Text(
                      l10n.uiCommercialRegister,
                      style: TextStyle(fontSize: 12, color: _mediumBlue),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            l10n.uiRequiredForCompanyAccountCreationAcceptedFormatsPdfJpgPng,
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
                          style: TextStyle(
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
                    child: Text(l10n.uiReplace),
                  ),
                ],
              ),
            ),
          ] else
            OutlinedButton.icon(
              onPressed: _pickCommercialRegister,
              icon: const Icon(Icons.upload_file_outlined),
              label: Text(l10n.uiUploadCommercialRegister),
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
    final l10n = AppLocalizations.of(context)!;
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
              child: Text(
                l10n.uiRegisterCompany,
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
    final l10n = AppLocalizations.of(context)!;
    return Center(
      child: RichText(
        text: TextSpan(
          text: l10n.uiAlreadyHaveAccountPrompt,
          style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
          children: [
            TextSpan(
              text: l10n.uiLogIn,
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
    final l10n = AppLocalizations.of(context)!;
    return Center(
      child: RichText(
        textAlign: TextAlign.center,
        text: TextSpan(
          style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
          children: [
            TextSpan(text: l10n.uiByRegisteringAgreePrefix),
            TextSpan(
              text: l10n.uiTermsOfUse,
              style: const TextStyle(
                decoration: TextDecoration.underline,
                fontWeight: FontWeight.w500,
              ),
            ),
            TextSpan(text: l10n.uiAndOur),
            TextSpan(
              text: l10n.uiPrivacyPolicy,
              style: const TextStyle(
                decoration: TextDecoration.underline,
                fontWeight: FontWeight.w500,
              ),
            ),
            TextSpan(text: l10n.uiBySigningUpAgreeSuffix),
          ],
        ),
      ),
    );
  }
}
