import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/auth_provider.dart';
import '../../widgets/shared/app_content_system.dart';
import '../../widgets/shared/app_feedback.dart';
import '../settings/logout_confirmation_sheet.dart';
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
  bool _seededInitialValue = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_seededInitialValue) {
      return;
    }

    final currentLevel =
        context.read<AuthProvider>().userModel?.academicLevel?.trim() ?? '';
    if (currentLevel.isNotEmpty) {
      _selectedLevel = currentLevel;
    }

    _seededInitialValue = true;
  }

  Future<void> _continue() async {
    final selectedLevel = _selectedLevel;
    if (selectedLevel == null) {
      return;
    }

    FocusScope.of(context).unfocus();

    final authProvider = context.read<AuthProvider>();
    final error = await authProvider.updateAcademicLevel(selectedLevel);

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
    final selectedLabel = _selectedLevel == null
        ? null
        : authAcademicLevelLabel(_selectedLevel!);

    return AuthFlowScaffold(
      trailing: IconButton(
        tooltip: 'Sign out',
        onPressed: authProvider.isLoading
            ? null
            : () => showLogoutConfirmationSheet(context),
        icon: const Icon(Icons.logout_rounded),
      ),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 580),
          child: AuthPanelCard(
            padding: const EdgeInsets.all(28),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                AuthCompactHeader(
                  icon: Icons.school_rounded,
                  title: 'Choose level',
                  subtitle: 'Select your academic level.',
                  stickers: <AuthStickerSpec>[
                    AuthStickerSpec(
                      icon: Icons.menu_book_rounded,
                      color: AuthFlowPalette.orange,
                    ),
                    AuthStickerSpec(
                      icon: Icons.auto_awesome_rounded,
                      color: Color(0xFF14B8A6),
                    ),
                    AuthStickerSpec(
                      icon: Icons.workspace_premium_rounded,
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
                    _SetupBadge(label: 'Step 1 of 2'),
                    if (needsProfileStep)
                      const _SetupBadge(label: 'Profile next'),
                    if (selectedLabel != null)
                      _SetupBadge(label: selectedLabel),
                  ],
                ),
                const SizedBox(height: 22),
                _LevelPicker(
                  selectedLevel: _selectedLevel,
                  onSelected: (value) => setState(() => _selectedLevel = value),
                ),
                const SizedBox(height: 22),
                AppPrimaryButton(
                  theme: authFlowTheme,
                  label: 'Continue',
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
                      : () => showLogoutConfirmationSheet(context),
                ),
              ],
            ),
          ),
        ),
      ),
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

class _LevelPicker extends StatelessWidget {
  final String? selectedLevel;
  final ValueChanged<String> onSelected;

  const _LevelPicker({required this.selectedLevel, required this.onSelected});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: authFlowTheme.surface.withValues(alpha: 0.78),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: authFlowTheme.border),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isWide = constraints.maxWidth >= 490;

          return GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: authAcademicLevels.length,
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: isWide ? 2 : 1,
              mainAxisSpacing: 10,
              crossAxisSpacing: 10,
              childAspectRatio: isWide ? 2.15 : 3.1,
            ),
            itemBuilder: (context, index) {
              final option = authAcademicLevels[index];
              final isSelected = selectedLevel == option.value;
              final accent = _levelAccent(option.value);

              return Material(
                color: Colors.transparent,
                child: InkWell(
                  borderRadius: BorderRadius.circular(20),
                  onTap: () => onSelected(option.value),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? accent.withValues(alpha: 0.1)
                          : authFlowTheme.surfaceMuted,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: isSelected ? accent : authFlowTheme.border,
                        width: isSelected ? 1.5 : 1,
                      ),
                    ),
                    child: Row(
                      children: <Widget>[
                        Container(
                          width: 38,
                          height: 38,
                          decoration: BoxDecoration(
                            color: isSelected
                                ? accent.withValues(alpha: 0.14)
                                : Colors.white,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(
                            option.icon,
                            color: isSelected
                                ? accent
                                : authFlowTheme.textMuted,
                            size: 19,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            option.label,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: authFlowTheme.section(
                              size: 13.5,
                              weight: FontWeight.w700,
                              color: authFlowTheme.textPrimary,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Icon(
                          isSelected
                              ? Icons.check_circle_rounded
                              : Icons.radio_button_unchecked_rounded,
                          color: isSelected ? accent : authFlowTheme.textMuted,
                          size: 18,
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

Color _levelAccent(String value) {
  switch (value) {
    case 'bac':
      return authFlowTheme.accent;
    case 'licence':
      return const Color(0xFF14B8A6);
    case 'master':
      return AuthFlowPalette.orange;
    case 'doctorat':
      return const Color(0xFF0F766E);
    default:
      return authFlowTheme.accent;
  }
}
