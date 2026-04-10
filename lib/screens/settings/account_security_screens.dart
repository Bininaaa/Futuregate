import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

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

    if (error != null) {
      context.showAppSnackBar(
        error,
        title: 'Password setup unavailable',
        type: AppFeedbackType.error,
      );
      return;
    }

    context.showAppSnackBar(
      'Password added successfully. You can now sign in with Google or email and password.',
      title: 'Password added',
      type: AppFeedbackType.success,
    );
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    if (!authProvider.canAddPassword) {
      return _UnsupportedSecurityAction(
        title: 'Add Password',
        bannerTitle: 'Password setup unavailable',
        bannerMessage: authProvider.canChangePassword
            ? 'This account already has email and password sign-in enabled.'
            : 'A password can only be added while signed in to a Google account that does not already have email/password linked.',
      );
    }

    final currentEmail = authProvider.userModel?.email ?? '';

    return SettingsPageScaffold(
      title: 'Add Password',
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SettingsInfoBanner(
              icon: Icons.password_rounded,
              title: 'Add email and password sign-in',
              message: currentEmail.isEmpty
                  ? 'Keep Google sign-in and add a password for this account.'
                  : 'Keep Google sign-in and add a password for $currentEmail.',
            ),
            const SizedBox(height: 18),
            SettingsPanel(
              child: Column(
                children: [
                  _PasswordField(
                    controller: _newPasswordController,
                    label: 'New Password',
                    obscureText: _obscureNew,
                    onToggle: () => setState(() => _obscureNew = !_obscureNew),
                    validator: Validators.validatePassword,
                  ),
                  const SizedBox(height: 10),
                  PasswordStrengthIndicator(password: _newPasswordText),
                  const SizedBox(height: 14),
                  _PasswordField(
                    controller: _confirmPasswordController,
                    label: 'Confirm Password',
                    obscureText: _obscureConfirm,
                    onToggle: () =>
                        setState(() => _obscureConfirm = !_obscureConfirm),
                    validator: (value) => Validators.validateConfirmPassword(
                      value,
                      _newPasswordController.text,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            Text(
              'Your sign-in email will remain managed by Google. This only adds an additional way to sign in.',
              style: SettingsFlowTheme.caption(),
            ),
            const SizedBox(height: 20),
            SettingsPrimaryButton(
              label: _loading ? 'Adding...' : 'Add Password',
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

    if (error != null) {
      context.showAppSnackBar(
        error,
        title: 'Password update unavailable',
        type: AppFeedbackType.error,
      );
      return;
    }

    context.showAppSnackBar(
      'Your password has been updated successfully.',
      title: 'Password updated',
      type: AppFeedbackType.success,
    );
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    if (!authProvider.canChangePassword) {
      return _UnsupportedSecurityAction(
        title: 'Change Password',
        bannerTitle: 'Password changes unavailable',
        bannerMessage: authProvider.canAddPassword
            ? 'This account uses Google sign-in right now. Add a password first, then you can change it later.'
            : 'Password changes are only available for accounts that already use email and password sign-in.',
      );
    }

    return SettingsPageScaffold(
      title: 'Change Password',
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SettingsInfoBanner(
              icon: Icons.lock_person_rounded,
              title: 'Secure your account',
              message:
                  'Use a strong password with a mix of letters, numbers, and symbols to keep your account protected.',
            ),
            const SizedBox(height: 18),
            SettingsPanel(
              child: Column(
                children: [
                  _PasswordField(
                    controller: _currentPasswordController,
                    label: 'Current Password',
                    obscureText: _obscureCurrent,
                    onToggle: () =>
                        setState(() => _obscureCurrent = !_obscureCurrent),
                    validator: Validators.validateLoginPassword,
                  ),
                  const SizedBox(height: 14),
                  _PasswordField(
                    controller: _newPasswordController,
                    label: 'New Password',
                    obscureText: _obscureNew,
                    onToggle: () => setState(() => _obscureNew = !_obscureNew),
                    validator: Validators.validatePassword,
                  ),
                  const SizedBox(height: 10),
                  PasswordStrengthIndicator(password: _newPasswordText),
                  const SizedBox(height: 14),
                  _PasswordField(
                    controller: _confirmPasswordController,
                    label: 'Confirm Password',
                    obscureText: _obscureConfirm,
                    onToggle: () =>
                        setState(() => _obscureConfirm = !_obscureConfirm),
                    validator: (value) => Validators.validateConfirmPassword(
                      value,
                      _newPasswordController.text,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 22),
            SettingsPrimaryButton(
              label: _loading ? 'Updating...' : 'Update Password',
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

    if (error != null) {
      context.showAppSnackBar(
        error,
        title: 'Email update unavailable',
        type: AppFeedbackType.error,
      );
      return;
    }

    context.showAppSnackBar(
      'Verification email sent. Confirm your new address to complete the update.',
      title: 'Verification sent',
      type: AppFeedbackType.success,
    );
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    if (!authProvider.canChangeEmail) {
      return _UnsupportedSecurityAction(
        title: 'Change Email',
        bannerTitle: 'Email changes unavailable',
        bannerMessage: authProvider.hasGoogleProvider
            ? 'This account is linked to Google, so the sign-in email must be managed through Google.'
            : 'Email changes are only available for accounts that use email and password without Google linked.',
      );
    }

    final currentEmail = authProvider.userModel?.email ?? '';

    return SettingsPageScaffold(
      title: 'Change Email',
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SettingsInfoBanner(
              icon: Icons.mark_email_read_outlined,
              title: 'Current email',
              message: currentEmail.isEmpty
                  ? 'No email is currently available for this account.'
                  : currentEmail,
            ),
            const SizedBox(height: 18),
            SettingsPanel(
              child: Column(
                children: [
                  _PasswordField(
                    controller: _passwordController,
                    label: 'Current Password',
                    obscureText: _obscurePassword,
                    onToggle: () =>
                        setState(() => _obscurePassword = !_obscurePassword),
                    validator: Validators.validateLoginPassword,
                  ),
                  const SizedBox(height: 14),
                  _TextField(
                    controller: _newEmailController,
                    label: 'New Email',
                    hintText: 'name@example.com',
                    keyboardType: TextInputType.emailAddress,
                    prefixIcon: Icons.email_outlined,
                    validator: Validators.validateEmail,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            Text(
              'A verification link will be sent to the new address before the change becomes active.',
              style: SettingsFlowTheme.caption(),
            ),
            const SizedBox(height: 20),
            SettingsPrimaryButton(
              label: _loading ? 'Updating...' : 'Update Email',
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
          borderSide: const BorderSide(color: SettingsFlowPalette.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: SettingsFlowTheme.radius(18),
          borderSide: const BorderSide(color: SettingsFlowPalette.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: SettingsFlowTheme.radius(18),
          borderSide: const BorderSide(color: SettingsFlowPalette.primary),
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
        prefixIcon: const Icon(
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
          borderSide: const BorderSide(color: SettingsFlowPalette.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: SettingsFlowTheme.radius(18),
          borderSide: const BorderSide(color: SettingsFlowPalette.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: SettingsFlowTheme.radius(18),
          borderSide: const BorderSide(color: SettingsFlowPalette.primary),
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
            label: 'Back',
            icon: Icons.arrow_back_rounded,
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),
    );
  }
}
