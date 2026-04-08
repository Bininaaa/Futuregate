import 'package:flutter/material.dart';
import '../utils/validators.dart';

class PasswordStrengthIndicator extends StatelessWidget {
  final String password;

  const PasswordStrengthIndicator({super.key, required this.password});

  @override
  Widget build(BuildContext context) {
    if (password.isEmpty) return const SizedBox.shrink();

    final rules = [
      _Rule('At least 8 characters', Validators.hasMinLength(password)),
      _Rule('One uppercase letter', Validators.hasUppercase(password)),
      _Rule('One lowercase letter', Validators.hasLowercase(password)),
      _Rule('One number', Validators.hasNumber(password)),
    ];

    final passed = rules.where((r) => r.met).length;
    final strength = passed / rules.length;

    Color barColor;
    if (strength <= 0.25) {
      barColor = Colors.red;
    } else if (strength <= 0.5) {
      barColor = Colors.orange;
    } else if (strength <= 0.75) {
      barColor = Colors.amber;
    } else {
      barColor = Colors.green;
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
            backgroundColor: Colors.grey.shade200,
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
                  color: rule.met ? Colors.green : Colors.grey.shade400,
                ),
                const SizedBox(width: 6),
                Text(
                  rule.label,
                  style: TextStyle(
                    fontSize: 12,
                    color: rule.met
                        ? Colors.green.shade700
                        : Colors.grey.shade500,
                    fontWeight: rule.met ? FontWeight.w500 : FontWeight.normal,
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
