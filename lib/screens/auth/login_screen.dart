import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../l10n/generated/app_localizations.dart';
import '../../providers/auth_provider.dart';
import '../../utils/validators.dart';
import '../../widgets/shared/app_content_system.dart';
import '../../widgets/shared/app_feedback.dart';
import 'auth_flow_widgets.dart';
import 'forgot_password_screen.dart';
import 'role_chooser_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  bool _obscurePassword = true;
  String? _formMessage;
  bool _submitted = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    FocusScope.of(context).unfocus();
    setState(() {
      _formMessage = null;
      _submitted = true;
    });

    if (!_formKey.currentState!.validate()) {
      return;
    }

    final authProvider = context.read<AuthProvider>();
    final error = await authProvider.login(
      email: _emailController.text.trim(),
      password: _passwordController.text,
    );

    if (!mounted || error == null) {
      return;
    }

    final l10n = AppLocalizations.of(context)!;
    setState(() {
      _formMessage = error == 'wrong-password'
          ? l10n.uiIncorrectEmailOrPassword
          : error;
    });
  }

  Future<void> _onGoogleSignIn() async {
    final authProvider = context.read<AuthProvider>();
    final error = await authProvider.signInWithGoogle();

    if (!mounted || error == null) {
      return;
    }

    final l10n = AppLocalizations.of(context)!;
    context.showAppSnackBar(
      error,
      title: l10n.uiGoogleSignInUnavailable,
      type: AppFeedbackType.error,
    );
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final l10n = AppLocalizations.of(context)!;

    return AuthFlowScaffold(
      showBrandBadge: false,
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 470),
          child: AuthPanelCard(
            padding: const EdgeInsets.all(28),
            child: AutofillGroup(
              child: Form(
                key: _formKey,
                autovalidateMode: _submitted
                    ? AutovalidateMode.onUserInteraction
                    : AutovalidateMode.disabled,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: <Widget>[
                    AuthCompactHeader(
                      icon: Icons.lock_person_rounded,
                      title: l10n.uiWelcomeBack,
                      subtitle: l10n.uiLoginToContinue,
                      stickers: const <AuthStickerSpec>[
                        AuthStickerSpec(
                          icon: Icons.verified_user_outlined,
                          color: Color(0xFF3B22F6),
                        ),
                        AuthStickerSpec(
                          icon: Icons.auto_awesome_outlined,
                          color: Color(0xFF14B8A6),
                        ),
                        AuthStickerSpec(
                          icon: Icons.work_outline_rounded,
                          color: Color(0xFF2563EB),
                        ),
                      ],
                    ),
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 180),
                      switchInCurve: Curves.easeOut,
                      switchOutCurve: Curves.easeIn,
                      child: (_formMessage ?? '').trim().isEmpty
                          ? const SizedBox.shrink()
                          : Padding(
                              key: const ValueKey<String>('login-error'),
                              padding: const EdgeInsets.only(top: 22),
                              child: AppInlineMessage(
                                type: AppFeedbackType.error,
                                title: l10n.uiLoginUnavailable,
                                message: _formMessage!,
                                compact: true,
                              ),
                            ),
                    ),
                    const SizedBox(height: 24),
                    AuthGoogleButton(
                      onPressed: authProvider.isLoading
                          ? null
                          : _onGoogleSignIn,
                    ),
                    const SizedBox(height: 18),
                    const AuthDivider(),
                    const SizedBox(height: 18),
                    AuthSectionLabel(l10n.uiAccountDetails),
                    const SizedBox(height: 14),
                    AuthTextField(
                      controller: _emailController,
                      label: l10n.uiEmail,
                      hint: l10n.uiEmailHint,
                      icon: Icons.email_outlined,
                      keyboardType: TextInputType.emailAddress,
                      validator: Validators.email(l10n),
                      textInputAction: TextInputAction.next,
                      autofillHints: const <String>[
                        AutofillHints.email,
                        AutofillHints.username,
                      ],
                      companyTone: true,
                    ),
                    const SizedBox(height: 14),
                    AuthTextField(
                      controller: _passwordController,
                      label: l10n.uiPassword,
                      hint: l10n.uiEnterYourPassword,
                      icon: Icons.lock_outline_rounded,
                      obscureText: _obscurePassword,
                      validator: Validators.loginPassword(l10n),
                      textInputAction: TextInputAction.done,
                      autofillHints: const <String>[AutofillHints.password],
                      onFieldSubmitted: (_) => _login(),
                      companyTone: true,
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscurePassword
                              ? Icons.visibility_off_outlined
                              : Icons.visibility_outlined,
                          color: authFlowTheme.textMuted,
                        ),
                        onPressed: () => setState(
                          () => _obscurePassword = !_obscurePassword,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Align(
                      alignment: AlignmentDirectional.centerEnd,
                      child: TextButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const ForgotPasswordScreen(),
                            ),
                          );
                        },
                        child: Text(
                          l10n.uiForgotPassword,
                          style: authFlowTheme.label(
                            size: 12.8,
                            color: authFlowTheme.accent,
                            weight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 6),
                    AppPrimaryButton(
                      theme: authFlowTheme,
                      label: l10n.uiLogin,
                      icon: Icons.login_rounded,
                      isBusy: authProvider.isLoading,
                      onPressed: authProvider.isLoading ? null : _login,
                    ),
                    const SizedBox(height: 18),
                    Center(
                      child: RichText(
                        text: TextSpan(
                          text: l10n.uiDontHaveAccountPrompt,
                          style: authFlowTheme.body(
                            size: 13.1,
                            color: authFlowTheme.textSecondary,
                            weight: FontWeight.w600,
                          ),
                          children: <InlineSpan>[
                            TextSpan(
                              text: l10n.uiCreateAccount,
                              style: authFlowTheme.label(
                                size: 13.1,
                                color: authFlowTheme.accent,
                                weight: FontWeight.w800,
                              ),
                              recognizer: TapGestureRecognizer()
                                ..onTap = () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => const RoleChooserScreen(),
                                    ),
                                  );
                                },
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
