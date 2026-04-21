import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../l10n/generated/app_localizations.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/shared/app_content_system.dart';
import '../../widgets/shared/app_feedback.dart';
import '../settings/logout_confirmation_sheet.dart';
import 'auth_flow_widgets.dart';

class EmailVerificationScreen extends StatefulWidget {
  const EmailVerificationScreen({super.key});

  @override
  State<EmailVerificationScreen> createState() =>
      _EmailVerificationScreenState();
}

class _EmailVerificationScreenState extends State<EmailVerificationScreen> {
  bool _checking = false;
  bool _resending = false;
  String? _message;
  bool _isError = false;

  Future<void> _checkVerification() async {
    setState(() {
      _checking = true;
      _message = null;
    });

    final authProvider = context.read<AuthProvider>();
    final verified = await authProvider.reloadAndCheckVerification();

    if (!mounted) {
      return;
    }

    if (verified) {
      await authProvider.loadCurrentUser();
    } else {
      final l10n = AppLocalizations.of(context)!;
      setState(() {
        _message = l10n.uiEmailNotVerifiedYet;
        _isError = true;
      });
    }

    if (mounted) {
      setState(() => _checking = false);
    }
  }

  Future<void> _resendEmail() async {
    setState(() {
      _resending = true;
      _message = null;
    });

    final authProvider = context.read<AuthProvider>();
    final error = await authProvider.sendEmailVerification();

    if (!mounted) {
      return;
    }

    final l10n = AppLocalizations.of(context)!;
    setState(() {
      _resending = false;
      _message = error ?? l10n.uiVerificationEmailSent;
      _isError = error != null;
    });
  }

  Future<void> _backToLogin() async {
    await showLogoutConfirmationSheet(context);
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final l10n = AppLocalizations.of(context)!;
    final email = (authProvider.userModel?.email ?? '').trim();

    return AuthFlowScaffold(
      showBrandBadge: false,
      trailing: IconButton(
        tooltip: l10n.uiSignOutTooltip,
        onPressed: _checking || _resending ? null : _backToLogin,
        icon: const Icon(Icons.logout_rounded),
      ),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 520),
          child: AuthPanelCard(
            padding: const EdgeInsets.all(28),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                AuthCompactHeader(
                  icon: Icons.mark_email_unread_outlined,
                  title: l10n.uiVerifyEmail,
                  subtitle: l10n.uiOpenYourInboxAndConfirmYourAccount,
                  stickers: <AuthStickerSpec>[
                    AuthStickerSpec(
                      icon: Icons.forward_to_inbox_rounded,
                      color: AuthFlowPalette.orange,
                    ),
                    AuthStickerSpec(
                      icon: Icons.shield_outlined,
                      color: Color(0xFF14B8A6),
                    ),
                    AuthStickerSpec(
                      icon: Icons.check_circle_outline_rounded,
                      color: Color(0xFF3B22F6),
                    ),
                  ],
                ),
                const SizedBox(height: 22),
                Wrap(
                  alignment: WrapAlignment.center,
                  spacing: 8,
                  runSpacing: 8,
                  children: <Widget>[
                    _VerificationBadge(label: l10n.uiEmailSignUp),
                    _VerificationBadge(label: l10n.uiOneQuickStep),
                  ],
                ),
                if (email.isNotEmpty) ...<Widget>[
                  const SizedBox(height: 18),
                  AuthReadOnlyTile(
                    label: l10n.uiEmail,
                    value: email,
                    icon: Icons.alternate_email_rounded,
                  ),
                ],
                if ((_message ?? '').trim().isNotEmpty) ...<Widget>[
                  const SizedBox(height: 18),
                  AppInlineMessage(
                    type: _isError
                        ? AppFeedbackType.error
                        : AppFeedbackType.success,
                    message: _message!,
                    compact: true,
                    accentColor: _isError ? null : const Color(0xFF179D6C),
                  ),
                ],
                const SizedBox(height: 22),
                AppPrimaryButton(
                  theme: authFlowTheme,
                  label: l10n.uiIVerified,
                  icon: Icons.check_circle_outline_rounded,
                  isBusy: _checking,
                  onPressed: _checking ? null : _checkVerification,
                ),
                const SizedBox(height: 10),
                AppSecondaryButton(
                  theme: authFlowTheme,
                  label: l10n.uiResendEmail,
                  icon: Icons.refresh_rounded,
                  onPressed: _resending ? null : _resendEmail,
                ),
                const SizedBox(height: 8),
                Center(
                  child: TextButton(
                    onPressed: _checking || _resending ? null : _backToLogin,
                    child: Text(
                      l10n.uiBackToLoginLower,
                      style: authFlowTheme.label(
                        size: 12.8,
                        color: authFlowTheme.textSecondary,
                        weight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _VerificationBadge extends StatelessWidget {
  final String label;

  const _VerificationBadge({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: authFlowTheme.surfaceMuted,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: authFlowTheme.border),
      ),
      child: Text(
        label,
        style: authFlowTheme.label(
          size: 10.9,
          color: authFlowTheme.textPrimary,
        ),
      ),
    );
  }
}
