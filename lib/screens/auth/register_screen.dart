import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../utils/validators.dart';
import '../../widgets/password_strength_indicator.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _fullNameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();
  final TextEditingController _researchTopicController =
      TextEditingController();
  final TextEditingController _laboratoryController = TextEditingController();
  final TextEditingController _supervisorController = TextEditingController();
  final TextEditingController _researchDomainController =
      TextEditingController();

  bool _obscurePassword = true;
  bool _obscureConfirm = true;
  String _selectedRole = 'bac';
  String _passwordText = '';

  static const Color _primaryOrange = Color(0xFFFF8C00);
  static const Color _darkPurple = Color(0xFF2D1B4E);

  final List<_ProfileOption> _profileOptions = const [
    _ProfileOption(
      value: 'bac',
      label: 'Bachelor',
      icon: Icons.school_outlined,
    ),
    _ProfileOption(
      value: 'licence',
      label: 'Licence Student',
      icon: Icons.menu_book_outlined,
    ),
    _ProfileOption(
      value: 'master',
      label: 'Master Student',
      icon: Icons.workspace_premium_outlined,
    ),
    _ProfileOption(
      value: 'doctorat',
      label: 'Doctorat Student',
      icon: Icons.science_outlined,
    ),
  ];

  @override
  void initState() {
    super.initState();
    _passwordController.addListener(() {
      setState(() => _passwordText = _passwordController.text);
    });
  }

  @override
  void dispose() {
    _fullNameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _researchTopicController.dispose();
    _laboratoryController.dispose();
    _supervisorController.dispose();
    _researchDomainController.dispose();
    super.dispose();
  }

  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) return;

    final authProvider = context.read<AuthProvider>();
    final error = await authProvider.register(
      fullName: _fullNameController.text.trim(),
      email: _emailController.text.trim(),
      password: _passwordController.text.trim(),
      selectedRole: _selectedRole,
      researchTopic: _researchTopicController.text.trim(),
      laboratory: _laboratoryController.text.trim(),
      supervisor: _supervisorController.text.trim(),
      researchDomain: _researchDomainController.text.trim(),
    );

    if (!mounted) return;
    if (error != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error),
          backgroundColor: Colors.red.shade400,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
    } else {
      Navigator.of(context).popUntil((route) => route.isFirst);
    }
  }

  Future<void> _onGoogleSignIn() async {
  final authProvider = context.read<AuthProvider>();
  final error = await authProvider.signInWithGoogle();

  if (!mounted) return;

  if (error != null) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(error),
        backgroundColor: Colors.red.shade400,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  } else {
    Navigator.of(context).popUntil((route) => route.isFirst);
  }
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
            colors: [
              Color(0xFFF5F0FF),
              Color(0xFFFFF5EB),
              Color(0xFFFFF0F5),
            ],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            child: Column(
              children: [
                _buildTopBar(),
                _buildIllustrationArea(),
                _buildMainCard(authProvider),
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
              color: Colors.white.withValues(alpha: 0.8),
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
              icon: const Icon(Icons.arrow_back, color: _darkPurple),
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
                color: _darkPurple,
              ),
            ),
          ),
          const SizedBox(width: 48),
        ],
      ),
    );
  }

  Widget _buildIllustrationArea() {
    return SizedBox(
      height: 180,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Positioned(
            top: 10,
            child: Icon(
              Icons.lightbulb,
              size: 50,
              color: Colors.amber.shade400,
            ),
          ),
          Positioned(
            left: 30,
            top: 40,
            child: Transform.rotate(
              angle: -0.2,
              child: Icon(
                Icons.description_outlined,
                size: 40,
                color: _primaryOrange.withValues(alpha: 0.6),
              ),
            ),
          ),
          Positioned(
            right: 30,
            top: 35,
            child: Icon(
              Icons.explore_outlined,
              size: 45,
              color: Colors.deepPurple.shade300,
            ),
          ),
          Positioned(
            left: 50,
            bottom: 30,
            child: Icon(
              Icons.public,
              size: 42,
              color: Colors.blue.shade300,
            ),
          ),
          Positioned(
            right: 50,
            bottom: 25,
            child: Icon(
              Icons.work_outline,
              size: 38,
              color: Colors.brown.shade300,
            ),
          ),
          Positioned(
            bottom: 10,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildPersonIcon(Colors.teal.shade300),
                const SizedBox(width: 8),
                _buildPersonIcon(Colors.orange.shade300),
                const SizedBox(width: 8),
                _buildPersonIcon(Colors.purple.shade300),
                const SizedBox(width: 8),
                _buildPersonIcon(Colors.blue.shade300),
              ],
            ),
          ),
          Positioned(
            left: 70,
            top: 70,
            child: Container(
              width: 55,
              height: 35,
              decoration: BoxDecoration(
                color: Colors.orange.shade100,
                borderRadius: BorderRadius.circular(6),
              ),
              child: Icon(Icons.auto_stories, size: 22, color: Colors.orange.shade700),
            ),
          ),
          Positioned(
            right: 70,
            top: 75,
            child: Container(
              width: 50,
              height: 35,
              decoration: BoxDecoration(
                color: Colors.purple.shade50,
                borderRadius: BorderRadius.circular(6),
              ),
              child: Icon(Icons.auto_stories, size: 20, color: Colors.purple.shade400),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPersonIcon(Color color) {
    return Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.2),
        shape: BoxShape.circle,
      ),
      child: Icon(Icons.person, size: 20, color: color),
    );
  }

  Widget _buildMainCard(AuthProvider authProvider) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 28),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.92),
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
            const Text(
              'Prepare your future',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: _darkPurple,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Opportunities, projects, and support\nfor students and researchers.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade600,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 20),
            _buildGoogleButton(),
            const SizedBox(height: 16),
            _buildDividerWithOr(),
            const SizedBox(height: 16),
            _buildTextField(
              controller: _fullNameController,
              label: 'Full Name',
              hint: 'Ex: Yasser Amine',
              icon: Icons.person_outline,
              validator: Validators.validateFullName,
            ),
            const SizedBox(height: 14),
            _buildTextField(
              controller: _emailController,
              label: 'Email',
              hint: 'email@exemple.com',
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
            const SizedBox(height: 20),
            _buildProfileSelection(),
            if (_selectedRole == 'doctorat') ...[
              const SizedBox(height: 16),
              _buildDoctoratFields(),
            ],
            const SizedBox(height: 24),
            _buildCreateAccountButton(authProvider),
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

  Widget _buildGoogleButton() {
    return OutlinedButton(
      onPressed: _onGoogleSignIn,
      style: OutlinedButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: 14),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(30),
        ),
        side: BorderSide(color: Colors.grey.shade300),
        backgroundColor: Colors.white,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 22,
            height: 22,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(4),
            ),
            child: const Text(
              'G',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFF4285F4),
              ),
            ),
          ),
          const SizedBox(width: 10),
          const Text(
            'Continue with Google',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDividerWithOr() {
    return Row(
      children: [
        Expanded(child: Divider(color: Colors.grey.shade300, thickness: 1)),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Text(
            'OR',
            style: TextStyle(
              fontSize: 13,
              color: Colors.grey.shade500,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        Expanded(child: Divider(color: Colors.grey.shade300, thickness: 1)),
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
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: _darkPurple,
          ),
        ),
        const SizedBox(height: 6),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          obscureText: obscureText,
          validator: validator,
          style: const TextStyle(fontSize: 14),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 13),
            prefixIcon: Icon(icon, size: 20, color: Colors.grey.shade500),
            suffixIcon: suffixIcon,
            filled: true,
            fillColor: Colors.grey.shade50,
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
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
              borderSide:
                  const BorderSide(color: _primaryOrange, width: 1.5),
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

  Widget _buildProfileSelection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Academic Level',
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: _darkPurple,
          ),
        ),
        const SizedBox(height: 10),
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 10,
          crossAxisSpacing: 10,
          childAspectRatio: 2.6,
          children: _profileOptions.map((option) {
            final isSelected = _selectedRole == option.value;
            return GestureDetector(
              onTap: () => setState(() => _selectedRole = option.value),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                decoration: BoxDecoration(
                  color: isSelected
                      ? _primaryOrange.withValues(alpha: 0.08)
                      : Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: isSelected ? _primaryOrange : Colors.grey.shade200,
                    width: isSelected ? 2 : 1,
                  ),
                  boxShadow: isSelected
                      ? [
                          BoxShadow(
                            color: _primaryOrange.withValues(alpha: 0.15),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ]
                      : null,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      option.icon,
                      size: 20,
                      color: isSelected ? _primaryOrange : Colors.grey.shade500,
                    ),
                    const SizedBox(width: 8),
                    Flexible(
                      child: Text(
                        option.label,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight:
                              isSelected ? FontWeight.w700 : FontWeight.w500,
                          color: isSelected ? _primaryOrange : Colors.grey.shade700,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildDoctoratFields() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.teal.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.teal.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.science, size: 18, color: Colors.teal.shade700),
              const SizedBox(width: 8),
              Text(
                'Research Information',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: Colors.teal.shade700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _buildTextField(
            controller: _researchTopicController,
            label: 'Research Topic',
            hint: 'Ex: Machine Learning in Healthcare',
            icon: Icons.topic_outlined,
          ),
          const SizedBox(height: 12),
          _buildTextField(
            controller: _laboratoryController,
            label: 'Laboratory',
            hint: 'Ex: LRIA',
            icon: Icons.biotech_outlined,
          ),
          const SizedBox(height: 12),
          _buildTextField(
            controller: _supervisorController,
            label: 'Supervisor',
            hint: 'Ex: Prof. Ahmed Benali',
            icon: Icons.person_outline,
          ),
          const SizedBox(height: 12),
          _buildTextField(
            controller: _researchDomainController,
            label: 'Research Domain',
            hint: 'Ex: Artificial Intelligence',
            icon: Icons.category_outlined,
          ),
        ],
      ),
    );
  }

  Widget _buildCreateAccountButton(AuthProvider authProvider) {
    return SizedBox(
      height: 52,
      child: authProvider.isLoading
          ? const Center(
              child: CircularProgressIndicator(color: _primaryOrange),
            )
          : ElevatedButton(
              onPressed: _register,
              style: ElevatedButton.styleFrom(
                backgroundColor: _primaryOrange,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
                elevation: 3,
                shadowColor: _primaryOrange.withValues(alpha: 0.4),
              ),
              child: const Text(
                'Create Account',
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
                color: _primaryOrange,
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
            TextSpan(text: 'By signing up, you agree to our '),
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

class _ProfileOption {
  final String value;
  final String label;
  final IconData icon;

  const _ProfileOption({
    required this.value,
    required this.label,
    required this.icon,
  });
}
