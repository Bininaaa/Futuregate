import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../l10n/generated/app_localizations.dart';
import '../../providers/auth_provider.dart';
import '../../utils/validators.dart';
import '../../widgets/password_strength_indicator.dart';
import '../../widgets/shared/app_feedback.dart';
import 'settings_flow_theme.dart';
import 'settings_flow_widgets.dart';

class AddPasswordScreen extends StatefulWidget {
  const AddPasswordScreen({super.key});

  @override
  State<AddPasswordScreen> createState() => _AddPasswordScreenState();
}

class _AddPasswordScreenState extends State<AddPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _obscureNew = true;
  bool _obscureConfirm = true;
  bool _loading = false;
  String _newPasswordText = '';

  @override
  void initState() {
    super.initState();
    _newPasswordController.addListener(() {
      if (!mounted) {
        return;
      }
      setState(() => _newPasswordText = _newPasswordController.text);
    });
  }

  @override
  void dispose() {
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() => _loading = true);

    final error = await context.read<AuthProvider>().addPassword(
      newPassword: _newPasswordController.text,
    );

    if (!mounted) {
      return;
    }

    setState(() => _loading = false);

    final l10n = AppLocalizations.of(context)!;
    if (error != null) {
      context.showAppSnackBar(
        error,
        title: l10n.uiPasswordSetupUnavailable,
        type: AppFeedbackType.error,
      );
      return;
    }

    context.showAppSnackBar(
      l10n.passwordAddedSuccessBody,
      title: l10n.uiPasswordAdded,
      type: AppFeedbackType.success,
    );
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final authProvider = context.watch<AuthProvider>();
    if (!authProvider.canAddPassword) {
      return _UnsupportedSecurityAction(
        title: l10n.addPasswordTitle,
        bannerTitle: l10n.uiPasswordSetupUnavailable,
        bannerMessage: authProvider.canChangePassword
            ? l10n.passwordSetupAlreadyEnabled
            : l10n.passwordSetupGoogleOnly,
      );
    }

    final currentEmail = authProvider.userModel?.email ?? '';

    return SettingsPageScaffold(
      title: l10n.addPasswordTitle,
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SettingsInfoBanner(
              icon: Icons.password_rounded,
              title: l10n.addPasswordBannerTitle,
              message: currentEmail.isEmpty
                  ? l10n.addPasswordBannerBodyGeneric
                  : l10n.addPasswordBannerBodyEmail(currentEmail),
            ),
            const SizedBox(height: 18),
            SettingsPanel(
              child: Column(
                children: [
                  _PasswordField(
                    controller: _newPasswordController,
                    label: l10n.newPasswordLabel,
                    obscureText: _obscureNew,
                    onToggle: () => setState(() => _obscureNew = !_obscureNew),
                    validator: Validators.password(l10n),
                  ),
                  const SizedBox(height: 10),
                  PasswordStrengthIndicator(password: _newPasswordText),
                  const SizedBox(height: 14),
                  _PasswordField(
                    controller: _confirmPasswordController,
                    label: l10n.confirmPasswordLabel,
                    obscureText: _obscureConfirm,
                    onToggle: () =>
                        setState(() => _obscureConfirm = !_obscureConfirm),
                    validator: Validators.confirmPassword(
                      l10n,
                      _newPasswordController.text,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            Text(
              l10n.addPasswordNote,
              style: SettingsFlowTheme.caption(),
            ),
            const SizedBox(height: 20),
            SettingsPrimaryButton(
              label: _loading ? l10n.addingPasswordLabel : l10n.addPasswordTitle,
              icon: _loading ? null : Icons.check_rounded,
              onPressed: _loading ? null : _submit,
            ),
          ],
        ),
      ),
    );
  }
}

class ChangePasswordScreen extends StatefulWidget {
  const ChangePasswordScreen({super.key});

  @override
  State<ChangePasswordScreen> createState() => _ChangePasswordScreenState();
}

class _ChangePasswordScreenState extends State<ChangePasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _currentPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _obscureCurrent = true;
  bool _obscureNew = true;
  bool _obscureConfirm = true;
  bool _loading = false;
  String _newPasswordText = '';

  @override
  void initState() {
    super.initState();
    _newPasswordController.addListener(() {
      if (!mounted) {
        return;
      }
      setState(() => _newPasswordText = _newPasswordController.text);
    });
  }

  @override
  void dispose() {
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() => _loading = true);

    final error = await context.read<AuthProvider>().changePassword(
      currentPassword: _currentPasswordController.text,
      newPassword: _newPasswordController.text,
    );

    if (!mounted) {
      return;
    }

    setState(() => _loading = false);

    final l10n = AppLocalizations.of(context)!;
    if (error != null) {
      context.showAppSnackBar(
        error,
        title: l10n.uiPasswordUpdateUnavailable,
        type: AppFeedbackType.error,
      );
      return;
    }

    context.showAppSnackBar(
      l10n.passwordUpdatedBody,
      title: l10n.uiPasswordUpdated,
      type: AppFeedbackType.success,
    );
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final authProvider = context.watch<AuthProvider>();
    if (!authProvider.canChangePassword) {
      return _UnsupportedSecurityAction(
        title: l10n.changePasswordTitle,
        bannerTitle: l10n.passwordChangesUnavailableTitle,
        bannerMessage: authProvider.canAddPassword
            ? l10n.passwordChangesGoogleBody
            : l10n.passwordChangesOnlyBody,
      );
    }

    return SettingsPageScaffold(
      title: l10n.changePasswordTitle,
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SettingsInfoBanner(
              icon: Icons.lock_person_rounded,
              title: l10n.secureAccountBannerTitle,
              message: l10n.secureAccountBannerBody,
            ),
            const SizedBox(height: 18),
            SettingsPanel(
              child: Column(
                children: [
                  _PasswordField(
                    controller: _currentPasswordController,
                    label: l10n.currentPasswordLabel,
                    obscureText: _obscureCurrent,
                    onToggle: () =>
                        setState(() => _obscureCurrent = !_obscureCurrent),
                    validator: Validators.loginPassword(l10n),
                  ),
                  const SizedBox(height: 14),
                  _PasswordField(
                    controller: _newPasswordController,
                    label: l10n.newPasswordLabel,
                    obscureText: _obscureNew,
                    onToggle: () => setState(() => _obscureNew = !_obscureNew),
                    validator: Validators.password(l10n),
                  ),
                  const SizedBox(height: 10),
                  PasswordStrengthIndicator(password: _newPasswordText),
                  const SizedBox(height: 14),
                  _PasswordField(
                    controller: _confirmPasswordController,
                    label: l10n.confirmPasswordLabel,
                    obscureText: _obscureConfirm,
                    onToggle: () =>
                        setState(() => _obscureConfirm = !_obscureConfirm),
                    validator: Validators.confirmPassword(
                      l10n,
                      _newPasswordController.text,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 22),
            SettingsPrimaryButton(
              label: _loading ? l10n.updatingPasswordLabel : l10n.updatePasswordLabel,
              icon: _loading ? null : Icons.check_rounded,
              onPressed: _loading ? null : _submit,
            ),
          ],
        ),
      ),
    );
  }
}

class ChangeEmailScreen extends StatefulWidget {
  const ChangeEmailScreen({super.key});

  @override
  State<ChangeEmailScreen> createState() => _ChangeEmailScreenState();
}

class _ChangeEmailScreenState extends State<ChangeEmailScreen> {
  final _formKey = GlobalKey<FormState>();
  final _passwordController = TextEditingController();
  final _newEmailController = TextEditingController();

  bool _loading = false;
  bool _obscurePassword = true;

  @override
  void dispose() {
    _passwordController.dispose();
    _newEmailController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() => _loading = true);

    final error = await context.read<AuthProvider>().changeEmail(
      currentPassword: _passwordController.text,
      newEmail: _newEmailController.text.trim(),
    );

    if (!mounted) {
      return;
    }

    setState(() => _loading = false);

    final l10n = AppLocalizations.of(context)!;
    if (error != null) {
      context.showAppSnackBar(
        error,
        title: l10n.uiEmailUpdateUnavailable,
        type: AppFeedbackType.error,
      );
      return;
    }

    context.showAppSnackBar(
      l10n.verificationSentBody,
      title: l10n.verificationSentTitle,
      type: AppFeedbackType.success,
    );
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final authProvider = context.watch<AuthProvider>();
    if (!authProvider.canChangeEmail) {
      return _UnsupportedSecurityAction(
        title: l10n.changeEmailTitle,
        bannerTitle: l10n.emailChangesUnavailableTitle,
        bannerMessage: authProvider.hasGoogleProvider
            ? l10n.emailChangesGoogleBody
            : l10n.emailChangesPasswordOnlyBody,
      );
    }

    final currentEmail = authProvider.userModel?.email ?? '';

    return SettingsPageScaffold(
      title: l10n.changeEmailTitle,
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SettingsInfoBanner(
              icon: Icons.mark_email_read_outlined,
              title: l10n.currentEmailBannerTitle,
              message: currentEmail.isEmpty
                  ? l10n.noEmailAvailableBody
                  : currentEmail,
            ),
            const SizedBox(height: 18),
            SettingsPanel(
              child: Column(
                children: [
                  _PasswordField(
                    controller: _passwordController,
                    label: l10n.currentPasswordLabel,
                    obscureText: _obscurePassword,
                    onToggle: () =>
                        setState(() => _obscurePassword = !_obscurePassword),
                    validator: Validators.loginPassword(l10n),
                  ),
                  const SizedBox(height: 14),
                  _TextField(
                    controller: _newEmailController,
                    label: l10n.newEmailLabel,
                    hintText: l10n.newEmailHint,
                    keyboardType: TextInputType.emailAddress,
                    prefixIcon: Icons.email_outlined,
                    validator: Validators.email(l10n),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            Text(
              l10n.emailVerificationNote,
              style: SettingsFlowTheme.caption(),
            ),
            const SizedBox(height: 20),
            SettingsPrimaryButton(
              label: _loading ? l10n.updatingEmailLabel : l10n.updateEmailLabel,
              icon: _loading ? null : Icons.arrow_forward_rounded,
              onPressed: _loading ? null : _submit,
            ),
          ],
        ),
      ),
    );
  }
}

class _TextField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final String? hintText;
  final TextInputType? keyboardType;
  final IconData? prefixIcon;
  final String? Function(String?)? validator;

  const _TextField({
    required this.controller,
    required this.label,
    this.hintText,
    this.keyboardType,
    this.prefixIcon,
    this.validator,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      validator: validator,
      style: SettingsFlowTheme.body(),
      decoration: InputDecoration(
        labelText: label,
        hintText: hintText,
        hintStyle: SettingsFlowTheme.caption(
          SettingsFlowPalette.textSecondary.withValues(alpha: 0.8),
        ),
        labelStyle: SettingsFlowTheme.caption(),
        prefixIcon: prefixIcon == null
            ? null
            : Icon(prefixIcon, color: SettingsFlowPalette.textSecondary),
        filled: true,
        fillColor: SettingsFlowPalette.background,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 16,
        ),
        border: OutlineInputBorder(
          borderRadius: SettingsFlowTheme.radius(18),
          borderSide: BorderSide(color: SettingsFlowPalette.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: SettingsFlowTheme.radius(18),
          borderSide: BorderSide(color: SettingsFlowPalette.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: SettingsFlowTheme.radius(18),
          borderSide: BorderSide(color: SettingsFlowPalette.primary),
        ),
      ),
    );
  }
}

class _PasswordField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final bool obscureText;
  final VoidCallback onToggle;
  final String? Function(String?)? validator;

  const _PasswordField({
    required this.controller,
    required this.label,
    required this.obscureText,
    required this.onToggle,
    this.validator,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      obscureText: obscureText,
      validator: validator,
      style: SettingsFlowTheme.body(),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: SettingsFlowTheme.caption(),
        prefixIcon: Icon(
          Icons.lock_outline_rounded,
          color: SettingsFlowPalette.textSecondary,
        ),
        suffixIcon: IconButton(
          onPressed: onToggle,
          icon: Icon(
            obscureText
                ? Icons.visibility_off_outlined
                : Icons.visibility_outlined,
            color: SettingsFlowPalette.textSecondary,
          ),
        ),
        filled: true,
        fillColor: SettingsFlowPalette.background,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 16,
        ),
        border: OutlineInputBorder(
          borderRadius: SettingsFlowTheme.radius(18),
          borderSide: BorderSide(color: SettingsFlowPalette.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: SettingsFlowTheme.radius(18),
          borderSide: BorderSide(color: SettingsFlowPalette.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: SettingsFlowTheme.radius(18),
          borderSide: BorderSide(color: SettingsFlowPalette.primary),
        ),
      ),
    );
  }
}

class _UnsupportedSecurityAction extends StatelessWidget {
  final String title;
  final String bannerTitle;
  final String bannerMessage;

  const _UnsupportedSecurityAction({
    required this.title,
    required this.bannerTitle,
    required this.bannerMessage,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return SettingsPageScaffold(
      title: title,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SettingsInfoBanner(
            icon: Icons.info_outline_rounded,
            title: bannerTitle,
            message: bannerMessage,
            color: SettingsFlowPalette.secondary,
          ),
          const SizedBox(height: 22),
          SettingsPrimaryButton(
            label: l10n.backLabel,
            icon: Icons.arrow_back_rounded,
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),
    );
  }
}
