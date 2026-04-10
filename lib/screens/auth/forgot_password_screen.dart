import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/auth_provider.dart';
import '../../utils/validators.dart';
import '../../widgets/shared/app_content_system.dart';
import '../../widgets/shared/app_feedback.dart';
import 'auth_flow_widgets.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _emailController = TextEditingController();

  bool _loading = false;
  bool _emailSent = false;
  String? _errorMessage;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _sendResetEmail() async {
    FocusScope.of(context).unfocus();

    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _loading = true;
      _errorMessage = null;
    });

    final authProvider = context.read<AuthProvider>();
    final error = await authProvider.sendPasswordResetEmail(
      _emailController.text.trim(),
    );

    if (!mounted) {
      return;
    }

    setState(() {
      _loading = false;
      _errorMessage = error;
      _emailSent = error == null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return AuthFlowScaffold(
      showBackButton: true,
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 500),
          child: AuthPanelCard(
            padding: const EdgeInsets.all(28),
            child: _emailSent ? _buildSuccessState() : _buildFormState(),
          ),
        ),
      ),
    );
  }

  Widget _buildFormState() {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          const AuthCompactHeader(
            icon: Icons.lock_reset_rounded,
            title: 'Reset password',
            subtitle: 'Enter your email to get a reset link.',
            stickers: <AuthStickerSpec>[
              AuthStickerSpec(
                icon: Icons.mail_outline_rounded,
                color: AuthFlowPalette.orange,
              ),
              AuthStickerSpec(
                icon: Icons.key_rounded,
                color: Color(0xFF14B8A6),
              ),
              AuthStickerSpec(
                icon: Icons.shield_outlined,
                color: Color(0xFF3B22F6),
              ),
            ],
          ),
          if ((_errorMessage ?? '').trim().isNotEmpty) ...<Widget>[
            const SizedBox(height: 22),
            AppInlineMessage(
              type: AppFeedbackType.error,
              title: 'Reset unavailable',
              message: _errorMessage!,
              compact: true,
            ),
          ],
          const SizedBox(height: 24),
          AuthTextField(
            controller: _emailController,
            label: 'Email',
            hint: 'email@example.com',
            icon: Icons.email_outlined,
            keyboardType: TextInputType.emailAddress,
            validator: Validators.validateEmail,
            textInputAction: TextInputAction.done,
            autofillHints: const <String>[AutofillHints.email],
            onFieldSubmitted: (_) => _sendResetEmail(),
          ),
          const SizedBox(height: 22),
          AppPrimaryButton(
            theme: authFlowTheme,
            label: 'Send Link',
            icon: Icons.send_rounded,
            isBusy: _loading,
            onPressed: _loading ? null : _sendResetEmail,
          ),
        ],
      ),
    );
  }

  Widget _buildSuccessState() {
    final email = _emailController.text.trim();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        const AuthCompactHeader(
          icon: Icons.mark_email_read_outlined,
          title: 'Check your email',
          subtitle: 'The reset link is on its way.',
          stickers: <AuthStickerSpec>[
            AuthStickerSpec(
              icon: Icons.check_circle_rounded,
              color: Color(0xFF179D6C),
            ),
            AuthStickerSpec(
              icon: Icons.mail_outline_rounded,
              color: AuthFlowPalette.orange,
            ),
          ],
        ),
        if (email.isNotEmpty) ...<Widget>[
          const SizedBox(height: 22),
          AuthReadOnlyTile(
            label: 'Sent to',
            value: email,
            icon: Icons.alternate_email_rounded,
          ),
        ],
        const SizedBox(height: 18),
        AppInlineMessage(
          type: AppFeedbackType.success,
          message: 'Open your inbox and follow the reset link.',
          compact: true,
          accentColor: const Color(0xFF179D6C),
        ),
        const SizedBox(height: 22),
        AppPrimaryButton(
          theme: authFlowTheme,
          label: 'Back to Login',
          icon: Icons.arrow_back_rounded,
          onPressed: () => Navigator.of(context).pop(),
        ),
        const SizedBox(height: 10),
        AppSecondaryButton(
          theme: authFlowTheme,
          label: 'Send Again',
          icon: Icons.refresh_rounded,
          onPressed: () {
            setState(() {
              _emailSent = false;
              _errorMessage = null;
            });
          },
        ),
      ],
    );
  }
}
