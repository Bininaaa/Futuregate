import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

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

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    FocusScope.of(context).unfocus();
    setState(() => _formMessage = null);

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

    setState(() {
      _formMessage = error == 'wrong-password'
          ? 'Incorrect email or password. Please try again.'
          : error;
    });
  }

  Future<void> _onGoogleSignIn() async {
    final authProvider = context.read<AuthProvider>();
    final error = await authProvider.signInWithGoogle();

    if (!mounted || error == null) {
      return;
    }

    context.showAppSnackBar(
      error,
      title: 'Google sign-in unavailable',
      type: AppFeedbackType.error,
    );
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();

    return AuthFlowScaffold(
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 470),
          child: AuthPanelCard(
            padding: const EdgeInsets.all(28),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  AuthCompactHeader(
                    icon: Icons.lock_person_rounded,
                    title: 'Welcome back',
                    subtitle: 'Login to continue.',
                    stickers: <AuthStickerSpec>[
                      AuthStickerSpec(
                        icon: Icons.school_rounded,
                        color: AuthFlowPalette.orange,
                      ),
                      AuthStickerSpec(
                        icon: Icons.auto_awesome_rounded,
                        color: Color(0xFF14B8A6),
                      ),
                      AuthStickerSpec(
                        icon: Icons.work_outline_rounded,
                        color: Color(0xFF3B22F6),
                      ),
                    ],
                  ),
                  if ((_formMessage ?? '').trim().isNotEmpty) ...<Widget>[
                    const SizedBox(height: 22),
                    AppInlineMessage(
                      type: AppFeedbackType.error,
                      title: 'Login unavailable',
                      message: _formMessage!,
                      compact: true,
                    ),
                  ],
                  const SizedBox(height: 24),
                  AuthGoogleButton(
                    onPressed: authProvider.isLoading ? null : _onGoogleSignIn,
                  ),
                  const SizedBox(height: 18),
                  const AuthDivider(),
                  const SizedBox(height: 18),
                  AuthTextField(
                    controller: _emailController,
                    label: 'Email',
                    hint: 'email@example.com',
                    icon: Icons.email_outlined,
                    keyboardType: TextInputType.emailAddress,
                    validator: Validators.validateEmail,
                    textInputAction: TextInputAction.next,
                    autofillHints: const <String>[AutofillHints.email],
                  ),
                  const SizedBox(height: 14),
                  AuthTextField(
                    controller: _passwordController,
                    label: 'Password',
                    hint: 'Enter your password',
                    icon: Icons.lock_outline_rounded,
                    obscureText: _obscurePassword,
                    validator: Validators.validateLoginPassword,
                    textInputAction: TextInputAction.done,
                    autofillHints: const <String>[AutofillHints.password],
                    onFieldSubmitted: (_) => _login(),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscurePassword
                            ? Icons.visibility_off_outlined
                            : Icons.visibility_outlined,
                        color: authFlowTheme.textMuted,
                      ),
                      onPressed: () =>
                          setState(() => _obscurePassword = !_obscurePassword),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Align(
                    alignment: Alignment.centerRight,
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
                        'Forgot password?',
                        style: authFlowTheme.label(
                          size: 12.8,
                          color: AuthFlowPalette.orange,
                          weight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 6),
                  AppPrimaryButton(
                    theme: authFlowTheme,
                    label: 'Login',
                    icon: Icons.login_rounded,
                    isBusy: authProvider.isLoading,
                    onPressed: authProvider.isLoading ? null : _login,
                  ),
                  const SizedBox(height: 18),
                  Center(
                    child: RichText(
                      text: TextSpan(
                        text: "Don't have an account? ",
                        style: authFlowTheme.body(
                          size: 13.1,
                          color: authFlowTheme.textSecondary,
                          weight: FontWeight.w600,
                        ),
                        children: <InlineSpan>[
                          TextSpan(
                            text: 'Create account',
                            style: authFlowTheme.label(
                              size: 13.1,
                              color: AuthFlowPalette.orange,
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
    );
  }
}
