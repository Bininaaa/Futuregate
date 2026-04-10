import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/auth_provider.dart';
import '../../widgets/shared/app_content_system.dart';
import '../../widgets/shared/app_feedback.dart';
import 'auth_flow_widgets.dart';

class AcademicLevelSelectionScreen extends StatefulWidget {
  const AcademicLevelSelectionScreen({super.key});

  @override
  State<AcademicLevelSelectionScreen> createState() =>
      _AcademicLevelSelectionScreenState();
}

class _AcademicLevelSelectionScreenState
    extends State<AcademicLevelSelectionScreen> {
  String? _selectedLevel;

  Future<void> _continue() async {
    if (_selectedLevel == null) {
      return;
    }

    final authProvider = context.read<AuthProvider>();
    final error = await authProvider.updateAcademicLevel(_selectedLevel!);

    if (!mounted || error == null) {
      return;
    }

    context.showAppSnackBar(
      error,
      title: 'Update unavailable',
      type: AppFeedbackType.error,
    );
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final needsProfileStep =
        authProvider.userModel?.needsStudentOnboarding ?? false;

    return AuthFlowScaffold(
      trailing: IconButton(
        tooltip: 'Sign out',
        onPressed: authProvider.isLoading ? null : authProvider.logout,
        icon: const Icon(Icons.logout_rounded),
      ),
      child: Center(
        child: AuthSplitLayout(
          hero: AuthHeroPanel(
            icon: Icons.school_rounded,
            eyebrow: 'Level setup',
            title:
                'Choose the academic level that should guide your student experience.',
            subtitle:
                'This step shapes discovery, profile context, and how the app tunes recommendations around your studies.',
            chips: const <String>[
              'Personalized feed',
              'Student profile',
              'Discover relevance',
            ],
            metrics: <AuthHeroMetric>[
              AuthHeroMetric(
                value: needsProfileStep ? '1/2' : 'Final',
                label: needsProfileStep ? 'Setup progress' : 'Setup stage',
              ),
            ],
            features: const <AuthFeaturePoint>[
              AuthFeaturePoint(
                title: 'Better recommendations',
                subtitle:
                    'Your level helps the app emphasize what feels realistic and useful for your current stage.',
                icon: Icons.track_changes_rounded,
                color: AuthFlowPalette.orange,
              ),
            ],
          ),
          content: AuthPanelCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                const AuthSectionHeading(
                  title: 'Select academic level',
                  subtitle:
                      'You can update it later, but getting it right now makes the student side of the app much sharper.',
                ),
                const SizedBox(height: 18),
                AuthProgressStrip(
                  step: 1,
                  total: needsProfileStep ? 2 : 1,
                  label: needsProfileStep
                      ? 'Level first, profile next'
                      : 'Last setup step',
                ),
                if (needsProfileStep) ...<Widget>[
                  const SizedBox(height: 14),
                  AppInlineMessage(
                    type: AppFeedbackType.info,
                    title: 'Next step',
                    message:
                        'After choosing your level, you will land on a short page to fill in your student information.',
                    compact: true,
                    accentColor: AuthFlowPalette.orange,
                  ),
                ],
                const SizedBox(height: 18),
                _buildLevelCards(),
                const SizedBox(height: 22),
                AppPrimaryButton(
                  theme: authFlowTheme,
                  label: needsProfileStep ? 'Continue to Profile' : 'Continue',
                  icon: Icons.arrow_forward_rounded,
                  isBusy: authProvider.isLoading,
                  onPressed: _selectedLevel == null || authProvider.isLoading
                      ? null
                      : _continue,
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

  Widget _buildLevelCards() {
    return Column(
      children: authAcademicLevels
          .map((level) {
            final isSelected = _selectedLevel == level.value;

            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: GestureDetector(
                onTap: () => setState(() => _selectedLevel = level.value),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: double.infinity,
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? authFlowTheme.accentSoft.withValues(alpha: 0.78)
                        : Colors.white.withValues(alpha: 0.92),
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(
                      color: isSelected
                          ? authFlowTheme.accent
                          : authFlowTheme.border,
                      width: isSelected ? 1.5 : 1,
                    ),
                    boxShadow: isSelected
                        ? <BoxShadow>[
                            BoxShadow(
                              color: authFlowTheme.accent.withValues(
                                alpha: 0.14,
                              ),
                              blurRadius: 20,
                              offset: const Offset(0, 14),
                            ),
                          ]
                        : <BoxShadow>[
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.04),
                              blurRadius: 14,
                              offset: const Offset(0, 8),
                            ),
                          ],
                  ),
                  child: Row(
                    children: <Widget>[
                      Container(
                        width: 46,
                        height: 46,
                        decoration: BoxDecoration(
                          color: isSelected
                              ? authFlowTheme.accent.withValues(alpha: 0.12)
                              : authFlowTheme.surfaceMuted,
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Icon(
                          level.icon,
                          size: 24,
                          color: isSelected
                              ? authFlowTheme.accent
                              : authFlowTheme.textMuted,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            Text(
                              level.label,
                              style: authFlowTheme.section(
                                size: 15.3,
                                weight: FontWeight.w700,
                                color: authFlowTheme.textPrimary,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              level.description,
                              style: authFlowTheme.body(
                                size: 11.8,
                                color: authFlowTheme.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (isSelected)
                        Container(
                          width: 26,
                          height: 26,
                          decoration: BoxDecoration(
                            color: authFlowTheme.accent,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.check,
                            size: 16,
                            color: Colors.white,
                          ),
                        )
                      else
                        Container(
                          width: 26,
                          height: 26,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: authFlowTheme.textMuted,
                              width: 2,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            );
          })
          .toList(growable: false),
    );
  }
}
