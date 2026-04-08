import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/shared/app_feedback.dart';

class AcademicLevelSelectionScreen extends StatefulWidget {
  const AcademicLevelSelectionScreen({super.key});

  @override
  State<AcademicLevelSelectionScreen> createState() =>
      _AcademicLevelSelectionScreenState();
}

class _AcademicLevelSelectionScreenState
    extends State<AcademicLevelSelectionScreen> {
  String? _selectedLevel;

  static const Color _primaryOrange = Color(0xFFFF8C00);
  static const Color _darkPurple = Color(0xFF2D1B4E);

  static const List<_LevelOption> _levels = [
    _LevelOption(
      value: 'bac',
      label: 'Bachelor',
      icon: Icons.school_outlined,
      description: 'Undergraduate level',
    ),
    _LevelOption(
      value: 'licence',
      label: 'Licence',
      icon: Icons.menu_book_outlined,
      description: 'Licence degree program',
    ),
    _LevelOption(
      value: 'master',
      label: 'Master',
      icon: Icons.workspace_premium_outlined,
      description: 'Master\'s degree program',
    ),
    _LevelOption(
      value: 'doctorat',
      label: 'Doctorat',
      icon: Icons.science_outlined,
      description: 'Doctoral research program',
    ),
  ];

  Future<void> _continue() async {
    if (_selectedLevel == null) return;

    final authProvider = context.read<AuthProvider>();
    final error = await authProvider.updateAcademicLevel(_selectedLevel!);

    if (!mounted) return;

    if (error != null) {
      context.showAppSnackBar(
        error,
        title: 'Update unavailable',
        type: AppFeedbackType.error,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFFF5F0FF), Color(0xFFFFF5EB), Color(0xFFFFF0F5)],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _buildHeader(),
                  const SizedBox(height: 36),
                  _buildLevelCards(),
                  const SizedBox(height: 32),
                  _buildContinueButton(authProvider),
                  const SizedBox(height: 20),
                  _buildLogoutButton(authProvider),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      children: [
        Container(
          width: 72,
          height: 72,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [_primaryOrange, Color(0xFFFFAA33)],
            ),
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: _primaryOrange.withValues(alpha: 0.3),
                blurRadius: 14,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: const Icon(
            Icons.school_rounded,
            size: 36,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 20),
        const Text(
          'Choose your academic level',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: _darkPurple,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'This helps us personalize your experience\nand show relevant opportunities.',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey.shade600,
            height: 1.5,
          ),
        ),
      ],
    );
  }

  Widget _buildLevelCards() {
    return Column(
      children: _levels.map((level) {
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
                    ? _primaryOrange.withValues(alpha: 0.08)
                    : Colors.white.withValues(alpha: 0.92),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(
                  color: isSelected ? _primaryOrange : Colors.grey.shade200,
                  width: isSelected ? 2 : 1,
                ),
                boxShadow: isSelected
                    ? [
                        BoxShadow(
                          color: _primaryOrange.withValues(alpha: 0.15),
                          blurRadius: 10,
                          offset: const Offset(0, 3),
                        ),
                      ]
                    : [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.04),
                          blurRadius: 6,
                          offset: const Offset(0, 2),
                        ),
                      ],
              ),
              child: Row(
                children: [
                  Container(
                    width: 46,
                    height: 46,
                    decoration: BoxDecoration(
                      color: isSelected
                          ? _primaryOrange.withValues(alpha: 0.15)
                          : Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Icon(
                      level.icon,
                      size: 24,
                      color: isSelected ? _primaryOrange : Colors.grey.shade500,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          level.label,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: isSelected ? _primaryOrange : _darkPurple,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          level.description,
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (isSelected)
                    Container(
                      width: 26,
                      height: 26,
                      decoration: const BoxDecoration(
                        color: _primaryOrange,
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
                          color: Colors.grey.shade300,
                          width: 2,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildContinueButton(AuthProvider authProvider) {
    final isEnabled = _selectedLevel != null && !authProvider.isLoading;
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: authProvider.isLoading
          ? const Center(
              child: CircularProgressIndicator(color: _primaryOrange),
            )
          : ElevatedButton(
              onPressed: isEnabled ? _continue : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: isEnabled
                    ? _primaryOrange
                    : Colors.grey.shade300,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
                elevation: isEnabled ? 3 : 0,
                shadowColor: _primaryOrange.withValues(alpha: 0.4),
              ),
              child: const Text(
                'Continue',
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.5,
                ),
              ),
            ),
    );
  }

  Widget _buildLogoutButton(AuthProvider authProvider) {
    return TextButton(
      onPressed: () => authProvider.logout(),
      child: Text(
        'Sign out',
        style: TextStyle(fontSize: 14, color: Colors.grey.shade500),
      ),
    );
  }
}

class _LevelOption {
  final String value;
  final String label;
  final IconData icon;
  final String description;

  const _LevelOption({
    required this.value,
    required this.label,
    required this.icon,
    required this.description,
  });
}
