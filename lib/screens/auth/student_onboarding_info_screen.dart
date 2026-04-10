import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/auth_provider.dart';
import '../../utils/validators.dart';
import '../../widgets/shared/app_content_system.dart';
import '../../widgets/shared/app_feedback.dart';
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

    context.showAppSnackBar(
      error,
      title: 'Profile setup unavailable',
      type: AppFeedbackType.error,
    );
  }

  String? _requiredValue(String label, String? value) {
    if (value == null || value.trim().isEmpty) {
      return '$label is required';
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final user = authProvider.userModel;
    final academicLevel = (user?.academicLevel ?? '').trim();
    final isDoctorat = academicLevel == 'doctorat';
    final levelOption = authLevelOption(
      academicLevel.isEmpty ? 'bac' : academicLevel,
    );
    final email = (user?.email ?? '').trim();

    return AuthFlowScaffold(
      trailing: IconButton(
        tooltip: 'Sign out',
        onPressed: authProvider.isLoading ? null : authProvider.logout,
        icon: const Icon(Icons.logout_rounded),
      ),
      child: AuthSplitLayout(
        hero: AuthHeroPanel(
          icon: Icons.badge_rounded,
          eyebrow: 'Profile step',
          title: 'Add the student details that personalize your experience.',
          subtitle:
              'We already created your account with Google. This short setup helps the app match you with stronger recommendations from day one.',
          chips: <String>[
            levelOption.label,
            'Google sign-in',
            'Editable later',
          ],
          metrics: const <AuthHeroMetric>[
            AuthHeroMetric(value: '2/2', label: 'Setup progress'),
            AuthHeroMetric(value: 'Student', label: 'Account role'),
          ],
          features: const <AuthFeaturePoint>[
            AuthFeaturePoint(
              title: 'Better matching',
              subtitle:
                  'University and field data improve what shows up in Discover and Scholarships.',
              icon: Icons.tune_rounded,
              color: AuthFlowPalette.orange,
            ),
            AuthFeaturePoint(
              title: 'Cleaner profile',
              subtitle:
                  'Your name, location, and bio shape how your student profile appears across the app.',
              icon: Icons.person_search_rounded,
              color: Color(0xFF14B8A6),
            ),
          ],
        ),
        content: AuthPanelCard(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                const AuthSectionHeading(
                  title: 'Finish your student setup',
                  subtitle:
                      'Complete the essentials now. You can refine everything later from Edit Profile.',
                ),
                const SizedBox(height: 18),
                const AuthProgressStrip(
                  step: 2,
                  total: 2,
                  label: 'Final details before home',
                ),
                const SizedBox(height: 18),
                if (email.isNotEmpty) ...<Widget>[
                  AuthReadOnlyTile(
                    label: 'Google account email',
                    value: email,
                    icon: Icons.alternate_email_rounded,
                  ),
                  const SizedBox(height: 16),
                ],
                AppInlineMessage(
                  type: AppFeedbackType.info,
                  title: 'Quick note',
                  message:
                      'Only your full name, university, and field of study are required here. The rest can stay lightweight for now.',
                  accentColor: AuthFlowPalette.orange,
                  compact: true,
                ),
                const SizedBox(height: 18),
                AuthTextField(
                  controller: _fullNameController,
                  label: 'Full Name',
                  hint: 'How you want your name to appear',
                  icon: Icons.badge_outlined,
                  validator: Validators.validateFullName,
                  textInputAction: TextInputAction.next,
                ),
                const SizedBox(height: 14),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Expanded(
                      child: AuthTextField(
                        controller: _universityController,
                        label: 'University',
                        hint: 'Your university or institute',
                        icon: Icons.school_outlined,
                        validator: (value) =>
                            _requiredValue('University', value),
                        textInputAction: TextInputAction.next,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: AuthTextField(
                        controller: _fieldOfStudyController,
                        label: 'Field of Study',
                        hint: 'Computer science, law, biology...',
                        icon: Icons.auto_stories_outlined,
                        validator: (value) =>
                            _requiredValue('Field of study', value),
                        textInputAction: TextInputAction.next,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Expanded(
                      child: AuthTextField(
                        controller: _phoneController,
                        label: 'Phone',
                        hint: '+213 ...',
                        icon: Icons.phone_outlined,
                        keyboardType: TextInputType.phone,
                        textInputAction: TextInputAction.next,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: AuthTextField(
                        controller: _locationController,
                        label: 'Location',
                        hint: 'City or region',
                        icon: Icons.location_on_outlined,
                        textInputAction: TextInputAction.next,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                AuthTextField(
                  controller: _bioController,
                  label: 'Bio',
                  hint: 'A short line about your interests, goals, or focus.',
                  icon: Icons.notes_rounded,
                  minLines: 3,
                  maxLines: 5,
                  textInputAction: TextInputAction.newline,
                ),
                if (isDoctorat) ...<Widget>[
                  const SizedBox(height: 18),
                  AppFormSectionCard(
                    theme: authFlowTheme.copyWithAccent(AuthFlowPalette.orange),
                    title: 'Doctorat details',
                    subtitle:
                        'Optional research details you already support in the student profile.',
                    child: Column(
                      children: <Widget>[
                        AuthTextField(
                          controller: _researchTopicController,
                          label: 'Research Topic',
                          hint: 'Your thesis or research direction',
                          icon: Icons.topic_outlined,
                          textInputAction: TextInputAction.next,
                        ),
                        const SizedBox(height: 12),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            Expanded(
                              child: AuthTextField(
                                controller: _laboratoryController,
                                label: 'Laboratory',
                                hint: 'Research lab or team',
                                icon: Icons.biotech_outlined,
                                textInputAction: TextInputAction.next,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: AuthTextField(
                                controller: _researchDomainController,
                                label: 'Research Domain',
                                hint: 'AI, materials, finance...',
                                icon: Icons.category_outlined,
                                textInputAction: TextInputAction.next,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        AuthTextField(
                          controller: _supervisorController,
                          label: 'Supervisor',
                          hint: 'Supervisor name',
                          icon: Icons.person_outline_rounded,
                          textInputAction: TextInputAction.done,
                        ),
                      ],
                    ),
                  ),
                ],
                const SizedBox(height: 22),
                AppPrimaryButton(
                  theme: authFlowTheme,
                  label: 'Finish Setup',
                  icon: Icons.check_circle_outline_rounded,
                  isBusy: authProvider.isLoading,
                  onPressed: authProvider.isLoading ? null : _submit,
                ),
                const SizedBox(height: 10),
                AppSecondaryButton(
                  theme: authFlowTheme,
                  label: 'Sign Out',
                  icon: Icons.logout_rounded,
                  onPressed: authProvider.isLoading
                      ? null
                      : authProvider.logout,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
