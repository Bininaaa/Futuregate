import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../l10n/generated/app_localizations.dart';
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
      final l10n = AppLocalizations.of(context)!;
      context.showAppSnackBar(
        error,
        title: l10n.uiAccountCreationUnavailableTitle,
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
      final l10n = AppLocalizations.of(context)!;
      context.showAppSnackBar(
        error,
        title: l10n.uiGoogleSignInUnavailable,
        type: AppFeedbackType.error,
      );
      return;
    }

    Navigator.of(context).popUntil((route) => route.isFirst);
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final l10n = AppLocalizations.of(context)!;

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
                    title: l10n.uiCreateAccount,
                    subtitle: l10n.uiStartYourStudentProfileSubtitle,
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
                    label: l10n.uiCreateAccountEff4,
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
    final l10n = AppLocalizations.of(context)!;
    return AuthTextField(
      controller: _fullNameController,
      label: l10n.uiFullName,
      hint: l10n.uiHowYourNameShouldAppear,
      icon: Icons.person_outline_rounded,
      validator: Validators.fullName(l10n),
      textInputAction: TextInputAction.next,
    );
  }

  Widget _buildEmailField() {
    final l10n = AppLocalizations.of(context)!;
    return AuthTextField(
      controller: _emailController,
      label: l10n.uiEmail,
      hint: l10n.uiEmailHint,
      icon: Icons.email_outlined,
      keyboardType: TextInputType.emailAddress,
      validator: Validators.email(l10n),
      textInputAction: TextInputAction.next,
      autofillHints: const <String>[AutofillHints.email],
    );
  }

  Widget _buildPasswordField() {
    final l10n = AppLocalizations.of(context)!;
    return AuthTextField(
      controller: _passwordController,
      label: l10n.uiPassword,
      hint: l10n.uiCreateAStrongPassword,
      icon: Icons.lock_outline_rounded,
      obscureText: _obscurePassword,
      validator: Validators.password(l10n),
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
    final l10n = AppLocalizations.of(context)!;
    return AuthTextField(
      controller: _confirmPasswordController,
      label: l10n.uiConfirmPassword,
      hint: l10n.uiRepeatYourPassword,
      icon: Icons.lock_outline_rounded,
      obscureText: _obscureConfirm,
      validator: Validators.confirmPassword(l10n, _passwordController.text),
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
    final l10n = AppLocalizations.of(context)!;
    final levels = authAcademicLevels(l10n);

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
            l10n.uiAcademicLevel,
            style: authFlowTheme.section(
              size: 14.4,
              weight: FontWeight.w700,
              color: authFlowTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 12),
          LayoutBuilder(
            builder: (context, constraints) {
              final isNarrow = constraints.maxWidth < 330;

              return GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: levels.length,
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: isNarrow ? 1 : 2,
                  mainAxisSpacing: 10,
                  crossAxisSpacing: 10,
                  mainAxisExtent: 76,
                ),
                itemBuilder: (context, index) {
                  final option = levels[index];
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
                        child: Row(
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
                      ),
                    ),
                  );
                },
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildDoctoratFields() {
    final l10n = AppLocalizations.of(context)!;
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
                l10n.uiResearchDetails,
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
                  l10n.uiOptional,
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
            label: l10n.uiResearchTopic,
            hint: l10n.uiResearchTopicHint,
            icon: Icons.topic_outlined,
          ),
          const SizedBox(height: 12),
          AuthTextField(
            controller: _laboratoryController,
            label: l10n.uiLaboratory,
            hint: l10n.uiLaboratoryHint,
            icon: Icons.biotech_outlined,
          ),
          const SizedBox(height: 12),
          AuthTextField(
            controller: _supervisorController,
            label: l10n.uiSupervisor,
            hint: l10n.uiSupervisorHint,
            icon: Icons.person_outline_rounded,
          ),
          const SizedBox(height: 12),
          AuthTextField(
            controller: _researchDomainController,
            label: l10n.uiResearchDomain,
            hint: l10n.uiResearchDomainHint,
            icon: Icons.category_outlined,
          ),
        ],
      ),
    );
  }

  Widget _buildLoginLink() {
    final l10n = AppLocalizations.of(context)!;
    return Center(
      child: RichText(
        text: TextSpan(
          text: l10n.uiAlreadyHaveAccountPrompt,
          style: authFlowTheme.body(
            size: 13.2,
            color: authFlowTheme.textSecondary,
            weight: FontWeight.w600,
          ),
          children: <InlineSpan>[
            TextSpan(
              text: l10n.uiLogIn,
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
    final l10n = AppLocalizations.of(context)!;
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
            TextSpan(text: l10n.uiBySigningUpAgreePrefix),
            TextSpan(
              text: l10n.uiTermsOfUse,
              style: authFlowTheme
                  .label(
                    size: 11.2,
                    color: authFlowTheme.textPrimary,
                    weight: FontWeight.w800,
                  )
                  .copyWith(decoration: TextDecoration.underline),
            ),
            TextSpan(text: l10n.uiAndOur),
            TextSpan(
              text: l10n.uiPrivacyPolicy,
              style: authFlowTheme
                  .label(
                    size: 11.2,
                    color: authFlowTheme.textPrimary,
                    weight: FontWeight.w800,
                  )
                  .copyWith(decoration: TextDecoration.underline),
            ),
            TextSpan(text: l10n.uiBySigningUpAgreeSuffix),
          ],
        ),
      ),
    );
  }
}
