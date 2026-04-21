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
  final TextEditingController _researchTopicController =
      TextEditingController();
  final TextEditingController _laboratoryController = TextEditingController();
  final TextEditingController _supervisorController = TextEditingController();
  final TextEditingController _researchDomainController =
      TextEditingController();

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
    _researchTopicController.text = (user?.researchTopic ?? '').trim();
    _laboratoryController.text = (user?.laboratory ?? '').trim();
    _supervisorController.text = (user?.supervisor ?? '').trim();
    _researchDomainController.text = (user?.researchDomain ?? '').trim();

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
    _researchTopicController.dispose();
    _laboratoryController.dispose();
    _supervisorController.dispose();
    _researchDomainController.dispose();
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
      researchTopic: _researchTopicController.text.trim(),
      laboratory: _laboratoryController.text.trim(),
      supervisor: _supervisorController.text.trim(),
      researchDomain: _researchDomainController.text.trim(),
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
    final isDoctorat = academicLevel == 'doctorat';
    final levelLabel = authLevelOption(
      academicLevel.isEmpty ? 'bac' : academicLevel,
      l10n,
    ).label;
    final email = (user?.email ?? '').trim();

    return AuthFlowScaffold(
      showBrandBadge: false,
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
            padding: const EdgeInsets.all(28),
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
                      _SetupBadge(label: l10n.uiStep2Of2),
                      _SetupBadge(label: levelLabel),
                      if (email.isNotEmpty) _SetupBadge(label: l10n.uiGoogle),
                    ],
                  ),
                  if (email.isNotEmpty || levelLabel.isNotEmpty) ...<Widget>[
                    const SizedBox(height: 18),
                    _ProfileMetaSection(email: email, levelLabel: levelLabel),
                  ],
                  const SizedBox(height: 18),
                  AuthTextField(
                    controller: _fullNameController,
                    label: l10n.uiFullName,
                    hint: l10n.uiHowYourNameShouldAppear,
                    icon: Icons.badge_outlined,
                    validator: Validators.fullName(l10n),
                    textInputAction: TextInputAction.next,
                    autofillHints: const <String>[AutofillHints.name],
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
                  if (isDoctorat) ...<Widget>[
                    const SizedBox(height: 16),
                    _ResearchCard(
                      researchTopicController: _researchTopicController,
                      laboratoryController: _laboratoryController,
                      supervisorController: _supervisorController,
                      researchDomainController: _researchDomainController,
                    ),
                  ],
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
    );
  }
}

class _SetupBadge extends StatelessWidget {
  final String label;

  const _SetupBadge({required this.label});

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

class _ProfileMetaSection extends StatelessWidget {
  final String email;
  final String levelLabel;

  const _ProfileMetaSection({required this.email, required this.levelLabel});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return LayoutBuilder(
      builder: (context, constraints) {
        final showTwoColumns = email.isNotEmpty && constraints.maxWidth >= 520;

        if (showTwoColumns) {
          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Expanded(
                child: AuthReadOnlyTile(
                  label: l10n.uiEmail,
                  value: email,
                  icon: Icons.alternate_email_rounded,
                  maxLines: 1,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: AuthReadOnlyTile(
                  label: l10n.uiLevel,
                  value: levelLabel,
                  icon: Icons.school_rounded,
                ),
              ),
            ],
          );
        }

        return Column(
          children: <Widget>[
            if (email.isNotEmpty) ...<Widget>[
              AuthReadOnlyTile(
                label: l10n.uiEmail,
                value: email,
                icon: Icons.alternate_email_rounded,
                maxLines: 1,
              ),
              const SizedBox(height: 12),
            ],
            AuthReadOnlyTile(
              label: l10n.uiLevel,
              value: levelLabel,
              icon: Icons.school_rounded,
            ),
          ],
        );
      },
    );
  }
}

class _ResearchCard extends StatelessWidget {
  final TextEditingController researchTopicController;
  final TextEditingController laboratoryController;
  final TextEditingController supervisorController;
  final TextEditingController researchDomainController;

  const _ResearchCard({
    required this.researchTopicController,
    required this.laboratoryController,
    required this.supervisorController,
    required this.researchDomainController,
  });

  @override
  Widget build(BuildContext context) {
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
                l10n.uiResearch,
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
            controller: researchTopicController,
            label: l10n.uiResearchTopic,
            hint: l10n.uiResearchTopicHint,
            icon: Icons.topic_outlined,
            textInputAction: TextInputAction.next,
          ),
          const SizedBox(height: 12),
          LayoutBuilder(
            builder: (context, constraints) {
              final isWide = constraints.maxWidth >= 520;

              if (isWide) {
                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Expanded(
                      child: AuthTextField(
                        controller: laboratoryController,
                        label: l10n.uiLaboratory,
                        hint: l10n.uiLabName,
                        icon: Icons.biotech_outlined,
                        textInputAction: TextInputAction.next,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: AuthTextField(
                        controller: researchDomainController,
                        label: l10n.uiResearchDomain,
                        hint: l10n.uiAiFinance,
                        icon: Icons.category_outlined,
                        textInputAction: TextInputAction.next,
                      ),
                    ),
                  ],
                );
              }

              return Column(
                children: <Widget>[
                  AuthTextField(
                    controller: laboratoryController,
                    label: l10n.uiLaboratory,
                    hint: l10n.uiLabName,
                    icon: Icons.biotech_outlined,
                    textInputAction: TextInputAction.next,
                  ),
                  const SizedBox(height: 12),
                  AuthTextField(
                    controller: researchDomainController,
                    label: l10n.uiResearchDomain,
                    hint: l10n.uiAiFinance,
                    icon: Icons.category_outlined,
                    textInputAction: TextInputAction.next,
                  ),
                ],
              );
            },
          ),
          const SizedBox(height: 12),
          AuthTextField(
            controller: supervisorController,
            label: l10n.uiSupervisor,
            hint: l10n.uiSupervisorHint,
            icon: Icons.person_outline_rounded,
            textInputAction: TextInputAction.done,
          ),
        ],
      ),
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
                color: authFlowTheme.accentSoft,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                Icons.notes_rounded,
                size: 18,
                color: authFlowTheme.accent,
              ),
            ),
            const SizedBox(width: 10),
            Text(
              l10n.uiAboutYou,
              style: authFlowTheme.label(
                size: 12.1,
                color: authFlowTheme.textPrimary,
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
              borderRadius: BorderRadius.circular(20),
              borderSide: BorderSide(color: authFlowTheme.border),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(20),
              borderSide: BorderSide(color: authFlowTheme.border),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(20),
              borderSide: BorderSide(color: authFlowTheme.accent, width: 1.4),
            ),
          ),
        ),
      ],
    );
  }
}
