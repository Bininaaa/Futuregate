import 'package:flutter/material.dart';
import '../l10n/generated/app_localizations.dart';
import '../theme/app_colors.dart';
import '../utils/validators.dart';

class PasswordStrengthIndicator extends StatelessWidget {
  final String password;

  const PasswordStrengthIndicator({super.key, required this.password});

  @override
  Widget build(BuildContext context) {
    if (password.isEmpty) return const SizedBox.shrink();

    final colors = AppColors.of(context);
    final l10n = AppLocalizations.of(context)!;
    final rules = [
      _Rule(
        l10n.validationPasswordMinLength,
        Validators.hasMinLength(password),
      ),
      _Rule(
        l10n.validationPasswordUppercase,
        Validators.hasUppercase(password),
      ),
      _Rule(
        l10n.validationPasswordLowercase,
        Validators.hasLowercase(password),
      ),
      _Rule(l10n.validationPasswordNumber, Validators.hasNumber(password)),
    ];

    final passed = rules.where((r) => r.met).length;
    final strength = passed / rules.length;

    Color barColor;
    if (strength <= 0.25) {
      barColor = colors.danger;
    } else if (strength <= 0.5) {
      barColor = colors.warning;
    } else if (strength <= 0.75) {
      barColor = colors.accent;
    } else {
      barColor = colors.success;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: strength,
            minHeight: 4,
            backgroundColor: colors.surfaceMuted,
            valueColor: AlwaysStoppedAnimation<Color>(barColor),
          ),
        ),
        const SizedBox(height: 8),
        ...rules.map(
          (rule) => Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: Row(
              children: [
                Icon(
                  rule.met ? Icons.check_circle : Icons.cancel,
                  size: 16,
                  color: rule.met ? colors.success : colors.textMuted,
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    rule.label,
                    style: TextStyle(
                      fontSize: 12,
                      color: rule.met ? colors.success : colors.textMuted,
                      fontWeight: rule.met
                          ? FontWeight.w600
                          : FontWeight.normal,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _Rule {
  final String label;
  final bool met;
  const _Rule(this.label, this.met);
}
