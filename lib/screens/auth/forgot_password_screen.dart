import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../l10n/generated/app_localizations.dart';
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
      showBrandBadge: false,
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
    final l10n = AppLocalizations.of(context)!;
    final errorPresentation = _buildErrorPresentation(l10n, _errorMessage);

    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          AuthCompactHeader(
            icon: Icons.lock_reset_rounded,
            title: l10n.uiResetPassword,
            subtitle: l10n.uiEnterYourEmailToGetAResetLink,
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
          if (errorPresentation != null) ...<Widget>[
            const SizedBox(height: 22),
            AppInlineMessage(
              type: errorPresentation.type,
              title: errorPresentation.title,
              message: errorPresentation.message,
              compact: true,
            ),
          ],
          const SizedBox(height: 24),
          AuthTextField(
            controller: _emailController,
            label: l10n.uiEmail,
            hint: l10n.uiEmailHint,
            icon: Icons.email_outlined,
            keyboardType: TextInputType.emailAddress,
            validator: Validators.email(l10n),
            textInputAction: TextInputAction.done,
            autofillHints: const <String>[AutofillHints.email],
            onFieldSubmitted: (_) => _sendResetEmail(),
          ),
          const SizedBox(height: 22),
          AppPrimaryButton(
            theme: authFlowTheme,
            label: l10n.uiSendLink,
            icon: Icons.send_rounded,
            isBusy: _loading,
            onPressed: _loading ? null : _sendResetEmail,
          ),
        ],
      ),
    );
  }

  Widget _buildSuccessState() {
    final l10n = AppLocalizations.of(context)!;
    final email = _emailController.text.trim();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        AuthCompactHeader(
          icon: Icons.mark_email_read_outlined,
          title: l10n.uiCheckYourEmail,
          subtitle: l10n.uiTheResetLinkIsOnItsWay,
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
            label: l10n.uiSentTo,
            value: email,
            icon: Icons.alternate_email_rounded,
          ),
        ],
        const SizedBox(height: 18),
        AppInlineMessage(
          type: AppFeedbackType.success,
          message: l10n.uiOpenYourInboxAndFollowTheResetLink,
          compact: true,
          accentColor: const Color(0xFF179D6C),
        ),
        const SizedBox(height: 22),
        AppPrimaryButton(
          theme: authFlowTheme,
          label: l10n.uiBackToLogin,
          icon: Icons.arrow_back_rounded,
          onPressed: () => Navigator.of(context).pop(),
        ),
        const SizedBox(height: 10),
        AppSecondaryButton(
          theme: authFlowTheme,
          label: l10n.uiSendAgain,
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

  _ResetFeedbackPresentation? _buildErrorPresentation(
    AppLocalizations l10n,
    String? message,
  ) {
    final trimmed = (message ?? '').trim();
    if (trimmed.isEmpty) {
      return null;
    }

    final lower = trimmed.toLowerCase();
    if (lower.contains('connection') || lower.contains('network')) {
      return _ResetFeedbackPresentation(
        type: AppFeedbackType.error,
        title: 'Connection problem',
        message: trimmed,
      );
    }

    if (lower.contains('temporarily unavailable') ||
        lower.contains('try again in a few minutes') ||
        lower.contains('try again in a moment')) {
      return _ResetFeedbackPresentation(
        type: AppFeedbackType.error,
        title: 'Temporary service issue',
        message: trimmed,
      );
    }

    return _ResetFeedbackPresentation(
      type: AppFeedbackType.error,
      title: l10n.uiResetUnavailable,
      message: trimmed,
    );
  }
}

class _ResetFeedbackPresentation {
  const _ResetFeedbackPresentation({
    required this.type,
    required this.title,
    required this.message,
  });

  final AppFeedbackType type;
  final String title;
  final String message;
}
