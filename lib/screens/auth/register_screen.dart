import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/auth_provider.dart';
import '../../utils/validators.dart';
import '../../widgets/password_strength_indicator.dart';
import '../../widgets/shared/app_content_system.dart';
import '../../widgets/shared/app_feedback.dart';
import 'auth_flow_widgets.dart';

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
    FocusScope.of(context).unfocus();

    if (!_formKey.currentState!.validate()) {
      return;
    }

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

    if (!mounted) {
      return;
    }

    if (error != null) {
      context.showAppSnackBar(
        error,
        title: 'Account creation unavailable',
        type: AppFeedbackType.error,
      );
      return;
    }

    Navigator.of(context).popUntil((route) => route.isFirst);
  }

  Future<void> _onGoogleSignIn() async {
    final authProvider = context.read<AuthProvider>();
    final error = await authProvider.signInWithGoogle();

    if (!mounted) {
      return;
    }

    if (error != null) {
      context.showAppSnackBar(
        error,
        title: 'Google sign-in unavailable',
        type: AppFeedbackType.error,
      );
      return;
    }

    Navigator.of(context).popUntil((route) => route.isFirst);
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();

    return AuthFlowScaffold(
      showBackButton: true,
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 580),
          child: AuthPanelCard(
            padding: const EdgeInsets.all(28),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  AuthCompactHeader(
                    icon: Icons.person_add_alt_1_rounded,
                    title: 'Create account',
                    subtitle: 'Start your student profile.',
                    stickers: <AuthStickerSpec>[
                      AuthStickerSpec(
                        icon: Icons.school_rounded,
                        color: AuthFlowPalette.orange,
                      ),
                      AuthStickerSpec(
                        icon: Icons.bolt_rounded,
                        color: Color(0xFF14B8A6),
                      ),
                      AuthStickerSpec(
                        icon: Icons.workspace_premium_rounded,
                        color: Color(0xFF3B22F6),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  AuthGoogleButton(
                    onPressed: authProvider.isLoading ? null : _onGoogleSignIn,
                  ),
                  const SizedBox(height: 18),
                  const AuthDivider(),
                  const SizedBox(height: 18),
                  LayoutBuilder(
                    builder: (context, constraints) {
                      final isWide = constraints.maxWidth >= 490;

                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: <Widget>[
                          if (isWide)
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: <Widget>[
                                Expanded(child: _buildFullNameField()),
                                const SizedBox(width: 12),
                                Expanded(child: _buildEmailField()),
                              ],
                            )
                          else ...<Widget>[
                            _buildFullNameField(),
                            const SizedBox(height: 14),
                            _buildEmailField(),
                          ],
                          const SizedBox(height: 14),
                          if (isWide)
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: <Widget>[
                                Expanded(child: _buildPasswordField()),
                                const SizedBox(width: 12),
                                Expanded(child: _buildConfirmPasswordField()),
                              ],
                            )
                          else ...<Widget>[
                            _buildPasswordField(),
                            const SizedBox(height: 14),
                            _buildConfirmPasswordField(),
                          ],
                        ],
                      );
                    },
                  ),
                  if (_passwordText.isNotEmpty) ...<Widget>[
                    const SizedBox(height: 10),
                    PasswordStrengthIndicator(password: _passwordText),
                  ],
                  const SizedBox(height: 20),
                  _buildProfileSelection(),
                  if (_selectedRole == 'doctorat') ...<Widget>[
                    const SizedBox(height: 16),
                    _buildDoctoratFields(),
                  ],
                  const SizedBox(height: 24),
                  AppPrimaryButton(
                    theme: authFlowTheme,
                    label: 'Create Account',
                    icon: Icons.arrow_forward_rounded,
                    isBusy: authProvider.isLoading,
                    onPressed: authProvider.isLoading ? null : _register,
                  ),
                  const SizedBox(height: 16),
                  _buildLoginLink(),
                  const SizedBox(height: 12),
                  _buildTermsText(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFullNameField() {
    return AuthTextField(
      controller: _fullNameController,
      label: 'Full Name',
      hint: 'How your name should appear',
      icon: Icons.person_outline_rounded,
      validator: Validators.validateFullName,
      textInputAction: TextInputAction.next,
    );
  }

  Widget _buildEmailField() {
    return AuthTextField(
      controller: _emailController,
      label: 'Email',
      hint: 'email@example.com',
      icon: Icons.email_outlined,
      keyboardType: TextInputType.emailAddress,
      validator: Validators.validateEmail,
      textInputAction: TextInputAction.next,
      autofillHints: const <String>[AutofillHints.email],
    );
  }

  Widget _buildPasswordField() {
    return AuthTextField(
      controller: _passwordController,
      label: 'Password',
      hint: 'Create a strong password',
      icon: Icons.lock_outline_rounded,
      obscureText: _obscurePassword,
      validator: Validators.validatePassword,
      textInputAction: TextInputAction.next,
      autofillHints: const <String>[AutofillHints.newPassword],
      suffixIcon: IconButton(
        icon: Icon(
          _obscurePassword
              ? Icons.visibility_off_outlined
              : Icons.visibility_outlined,
          color: authFlowTheme.textMuted,
        ),
        onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
      ),
    );
  }

  Widget _buildConfirmPasswordField() {
    return AuthTextField(
      controller: _confirmPasswordController,
      label: 'Confirm Password',
      hint: 'Repeat your password',
      icon: Icons.lock_outline_rounded,
      obscureText: _obscureConfirm,
      validator: (value) =>
          Validators.validateConfirmPassword(value, _passwordController.text),
      textInputAction: TextInputAction.done,
      autofillHints: const <String>[AutofillHints.newPassword],
      suffixIcon: IconButton(
        icon: Icon(
          _obscureConfirm
              ? Icons.visibility_off_outlined
              : Icons.visibility_outlined,
          color: authFlowTheme.textMuted,
        ),
        onPressed: () => setState(() => _obscureConfirm = !_obscureConfirm),
      ),
    );
  }

  Widget _buildProfileSelection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: authFlowTheme.surface.withValues(alpha: 0.78),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: authFlowTheme.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            'Academic Level',
            style: authFlowTheme.section(
              size: 14.4,
              weight: FontWeight.w700,
              color: authFlowTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 12),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: authAcademicLevels.length,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              mainAxisSpacing: 10,
              crossAxisSpacing: 10,
              childAspectRatio: 2.15,
            ),
            itemBuilder: (context, index) {
              final option = authAcademicLevels[index];
              final isSelected = _selectedRole == option.value;

              return Material(
                color: Colors.transparent,
                child: InkWell(
                  borderRadius: BorderRadius.circular(20),
                  onTap: () => setState(() => _selectedRole = option.value),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? authFlowTheme.accentSoft.withValues(alpha: 0.82)
                          : authFlowTheme.surfaceMuted,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: isSelected
                            ? authFlowTheme.accent
                            : authFlowTheme.border,
                        width: isSelected ? 1.5 : 1,
                      ),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: <Widget>[
                        Row(
                          children: <Widget>[
                            Container(
                              width: 36,
                              height: 36,
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? authFlowTheme.accent.withValues(
                                        alpha: 0.12,
                                      )
                                    : Colors.white,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Icon(
                                option.icon,
                                color: isSelected
                                    ? authFlowTheme.accent
                                    : authFlowTheme.textMuted,
                                size: 18,
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                option.label,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: authFlowTheme.section(
                                  size: 13.3,
                                  weight: FontWeight.w700,
                                  color: authFlowTheme.textPrimary,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Icon(
                              isSelected
                                  ? Icons.check_circle_rounded
                                  : Icons.radio_button_unchecked_rounded,
                              color: isSelected
                                  ? authFlowTheme.accent
                                  : authFlowTheme.textMuted,
                              size: 18,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildDoctoratFields() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AuthFlowPalette.orangeSoft.withValues(alpha: 0.55),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: AuthFlowPalette.orange.withValues(alpha: 0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Text(
                'Research details',
                style: authFlowTheme.section(
                  size: 14.3,
                  color: authFlowTheme.textPrimary,
                  weight: FontWeight.w700,
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.7),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  'Optional',
                  style: authFlowTheme.label(
                    size: 10.7,
                    color: AuthFlowPalette.orange,
                    weight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          AuthTextField(
            controller: _researchTopicController,
            label: 'Research Topic',
            hint: 'Machine learning in healthcare',
            icon: Icons.topic_outlined,
          ),
          const SizedBox(height: 12),
          AuthTextField(
            controller: _laboratoryController,
            label: 'Laboratory',
            hint: 'Research laboratory',
            icon: Icons.biotech_outlined,
          ),
          const SizedBox(height: 12),
          AuthTextField(
            controller: _supervisorController,
            label: 'Supervisor',
            hint: 'Supervisor name',
            icon: Icons.person_outline_rounded,
          ),
          const SizedBox(height: 12),
          AuthTextField(
            controller: _researchDomainController,
            label: 'Research Domain',
            hint: 'Artificial intelligence',
            icon: Icons.category_outlined,
          ),
        ],
      ),
    );
  }

  Widget _buildLoginLink() {
    return Center(
      child: RichText(
        text: TextSpan(
          text: 'Already have an account? ',
          style: authFlowTheme.body(
            size: 13.2,
            color: authFlowTheme.textSecondary,
            weight: FontWeight.w600,
          ),
          children: <InlineSpan>[
            TextSpan(
              text: 'Log in',
              style: authFlowTheme.label(
                size: 13.2,
                color: AuthFlowPalette.orange,
                weight: FontWeight.w800,
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
          style: authFlowTheme.body(
            size: 11.2,
            height: 1.5,
            color: authFlowTheme.textMuted,
            weight: FontWeight.w600,
          ),
          children: <InlineSpan>[
            const TextSpan(text: 'By signing up, you agree to our '),
            TextSpan(
              text: 'Terms of Use',
              style: authFlowTheme
                  .label(
                    size: 11.2,
                    color: authFlowTheme.textPrimary,
                    weight: FontWeight.w800,
                  )
                  .copyWith(decoration: TextDecoration.underline),
            ),
            const TextSpan(text: ' and our '),
            TextSpan(
              text: 'Privacy Policy',
              style: authFlowTheme
                  .label(
                    size: 11.2,
                    color: authFlowTheme.textPrimary,
                    weight: FontWeight.w800,
                  )
                  .copyWith(decoration: TextDecoration.underline),
            ),
            const TextSpan(text: '.'),
          ],
        ),
      ),
    );
  }
}
