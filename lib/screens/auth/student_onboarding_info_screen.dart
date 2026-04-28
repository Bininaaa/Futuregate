import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../l10n/generated/app_localizations.dart';
import '../../providers/auth_provider.dart';
import '../../utils/validators.dart';
import '../../widgets/shared/app_content_system.dart';
import '../../widgets/shared/app_feedback.dart';
import '../settings/logout_confirmation_sheet.dart';
import 'auth_flow_widgets.dart';

class StudentOnboardingInfoScreen extends StatefulWidget {
  const StudentOnboardingInfoScreen({super.key});

  @override
  State<StudentOnboardingInfoScreen> createState() =>
      _StudentOnboardingInfoScreenState();
}

class _StudentOnboardingInfoScreenState
    extends State<StudentOnboardingInfoScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _fullNameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _locationController = TextEditingController();
  final TextEditingController _universityController = TextEditingController();
  final TextEditingController _fieldOfStudyController = TextEditingController();
  final TextEditingController _bioController = TextEditingController();

  bool _initialized = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_initialized) {
      return;
    }

    final user = context.read<AuthProvider>().userModel;
    _fullNameController.text = (user?.fullName ?? '').trim();
    _phoneController.text = (user?.phone ?? '').trim();
    _locationController.text = (user?.location ?? '').trim();
    _universityController.text = (user?.university ?? '').trim();
    _fieldOfStudyController.text = (user?.fieldOfStudy ?? '').trim();
    _bioController.text = (user?.bio ?? '').trim();

    _initialized = true;
  }

  @override
  void dispose() {
    _fullNameController.dispose();
    _phoneController.dispose();
    _locationController.dispose();
    _universityController.dispose();
    _fieldOfStudyController.dispose();
    _bioController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final authProvider = context.read<AuthProvider>();
    final error = await authProvider.completeStudentOnboarding(
      fullName: _fullNameController.text.trim(),
      phone: _phoneController.text.trim(),
      location: _locationController.text.trim(),
      university: _universityController.text.trim(),
      fieldOfStudy: _fieldOfStudyController.text.trim(),
      bio: _bioController.text.trim(),
    );

    if (!mounted || error == null) {
      return;
    }

    final l10n = AppLocalizations.of(context)!;
    context.showAppSnackBar(
      error,
      title: l10n.uiProfileSetupUnavailable,
      type: AppFeedbackType.error,
    );
  }

  String? _requiredValue(String? value) {
    if (value == null || value.trim().isEmpty) {
      final l10n = AppLocalizations.of(context)!;
      return l10n.uiFieldIsRequired('');
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final l10n = AppLocalizations.of(context)!;
    final user = authProvider.userModel;
    final academicLevel = (user?.academicLevel ?? '').trim();
    final levelLabel = authLevelOption(
      academicLevel.isEmpty ? 'bac' : academicLevel,
      l10n,
    ).label;
    final email = (user?.email ?? '').trim();

    return AuthFlowScaffold(
      showBrandBadge: true,
      trailing: IconButton(
        tooltip: l10n.uiSignOutTooltip,
        onPressed: authProvider.isLoading
            ? null
            : () => showLogoutConfirmationSheet(context),
        icon: const Icon(Icons.logout_rounded),
      ),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 620),
          child: AuthPanelCard(
            padding: const EdgeInsets.fromLTRB(22, 24, 22, 22),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  AuthCompactHeader(
                    icon: Icons.badge_rounded,
                    title: l10n.uiFinishProfile,
                    subtitle: l10n.uiAddYourStudentDetails,
                    stickers: <AuthStickerSpec>[
                      AuthStickerSpec(
                        icon: Icons.school_rounded,
                        color: AuthFlowPalette.orange,
                      ),
                      AuthStickerSpec(
                        icon: Icons.person_rounded,
                        color: Color(0xFF14B8A6),
                      ),
                      AuthStickerSpec(
                        icon: Icons.check_circle_rounded,
                        color: AuthFlowPalette.link,
                      ),
                    ],
                    badges: <String>[
                      l10n.uiStep2Of2,
                      levelLabel,
                      if (email.isNotEmpty) l10n.uiGoogle,
                    ],
                  ),
                  const SizedBox(height: 22),
                  AuthSectionLabel(l10n.uiStudentDetails),
                  const SizedBox(height: 14),
                  AuthTextField(
                    controller: _fullNameController,
                    label: l10n.uiFullName,
                    hint: l10n.uiHowYourNameShouldAppear,
                    icon: Icons.badge_outlined,
                    validator: Validators.fullName(l10n),
                    textInputAction: TextInputAction.next,
                    autofillHints: const <String>[AutofillHints.name],
                    companyTone: true,
                  ),
                  const SizedBox(height: 14),
                  LayoutBuilder(
                    builder: (context, constraints) {
                      final isWide = constraints.maxWidth >= 520;

                      if (isWide) {
                        return Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            Expanded(child: _buildUniversityField()),
                            const SizedBox(width: 12),
                            Expanded(child: _buildFieldOfStudyField()),
                          ],
                        );
                      }

                      return Column(
                        children: <Widget>[
                          _buildUniversityField(),
                          const SizedBox(height: 14),
                          _buildFieldOfStudyField(),
                        ],
                      );
                    },
                  ),
                  const SizedBox(height: 14),
                  LayoutBuilder(
                    builder: (context, constraints) {
                      final isWide = constraints.maxWidth >= 520;

                      if (isWide) {
                        return Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            Expanded(child: _buildPhoneField()),
                            const SizedBox(width: 12),
                            Expanded(child: _buildLocationField()),
                          ],
                        );
                      }

                      return Column(
                        children: <Widget>[
                          _buildPhoneField(),
                          const SizedBox(height: 14),
                          _buildLocationField(),
                        ],
                      );
                    },
                  ),
                  const SizedBox(height: 14),
                  _AboutYouField(controller: _bioController),
                  const SizedBox(height: 22),
                  AppPrimaryButton(
                    theme: authFlowTheme,
                    label: l10n.uiFinish,
                    icon: Icons.check_circle_outline_rounded,
                    isBusy: authProvider.isLoading,
                    onPressed: authProvider.isLoading ? null : _submit,
                  ),
                  const SizedBox(height: 10),
                  AppSecondaryButton(
                    theme: authFlowTheme,
                    label: l10n.uiSignOut,
                    icon: Icons.logout_rounded,
                    onPressed: authProvider.isLoading
                        ? null
                        : () => showLogoutConfirmationSheet(context),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildUniversityField() {
    final l10n = AppLocalizations.of(context)!;
    return AuthTextField(
      controller: _universityController,
      label: l10n.uiUniversity,
      hint: l10n.uiYourUniversity,
      icon: Icons.school_outlined,
      validator: (value) => _requiredValue(value),
      textInputAction: TextInputAction.next,
      companyTone: true,
    );
  }

  Widget _buildFieldOfStudyField() {
    final l10n = AppLocalizations.of(context)!;
    return AuthTextField(
      controller: _fieldOfStudyController,
      label: l10n.uiFieldOfStudy,
      hint: l10n.uiComputerScience,
      icon: Icons.auto_stories_outlined,
      validator: (value) => _requiredValue(value),
      textInputAction: TextInputAction.next,
      companyTone: true,
    );
  }

  Widget _buildPhoneField() {
    final l10n = AppLocalizations.of(context)!;
    return AuthTextField(
      controller: _phoneController,
      label: l10n.uiPhone,
      hint: l10n.uiPhoneHint,
      icon: Icons.phone_outlined,
      keyboardType: TextInputType.phone,
      textInputAction: TextInputAction.next,
      autofillHints: const <String>[AutofillHints.telephoneNumber],
      companyTone: true,
    );
  }

  Widget _buildLocationField() {
    final l10n = AppLocalizations.of(context)!;
    return AuthTextField(
      controller: _locationController,
      label: l10n.uiLocation,
      hint: l10n.uiCity,
      icon: Icons.location_on_outlined,
      textInputAction: TextInputAction.next,
      autofillHints: const <String>[AutofillHints.addressCity],
      companyTone: true,
    );
  }
}

class _AboutYouField extends StatelessWidget {
  final TextEditingController controller;

  const _AboutYouField({required this.controller});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Row(
          children: <Widget>[
            Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                color: AuthFlowPalette.linkSoft,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                Icons.notes_rounded,
                size: 18,
                color: AuthFlowPalette.link,
              ),
            ),
            const SizedBox(width: 10),
            Text(
              l10n.uiAboutYou,
              style: authFlowTheme.label(
                size: 13,
                color: authFlowTheme.textPrimary,
                weight: FontWeight.w700,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          minLines: 3,
          maxLines: 4,
          keyboardType: TextInputType.multiline,
          textInputAction: TextInputAction.newline,
          textAlignVertical: TextAlignVertical.top,
          style: authFlowTheme.body(
            size: 13.4,
            color: authFlowTheme.textPrimary,
            weight: FontWeight.w600,
          ),
          decoration: InputDecoration(
            hintText: l10n.uiShortIntro,
            hintStyle: authFlowTheme.body(
              size: 12.6,
              color: authFlowTheme.textMuted,
            ),
            filled: true,
            fillColor: authFlowTheme.surfaceMuted,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 18,
              vertical: 16,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(color: authFlowTheme.border),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(color: authFlowTheme.border),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(color: authFlowTheme.accent, width: 1.4),
            ),
          ),
        ),
      ],
    );
  }
}
