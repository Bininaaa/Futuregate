import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/auth_provider.dart';
import 'settings_flow_theme.dart';
import 'settings_flow_widgets.dart';

Future<void> showLogoutConfirmationSheet(BuildContext context) async {
  final confirmed = await showModalBottomSheet<bool>(
    context: context,
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
    builder: (sheetContext) => const LogoutConfirmationSheet(),
  );

  if (confirmed == true && context.mounted) {
    await context.read<AuthProvider>().logout();
  }
}

class LogoutConfirmationSheet extends StatelessWidget {
  const LogoutConfirmationSheet({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 20),
      decoration: BoxDecoration(
        color: SettingsFlowPalette.surface,
        borderRadius: SettingsFlowTheme.radius(26),
        boxShadow: SettingsFlowTheme.softShadow(0.12),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 40,
            height: 5,
            decoration: BoxDecoration(
              color: SettingsFlowPalette.border,
              borderRadius: SettingsFlowTheme.radius(999),
            ),
          ),
          const SizedBox(height: 16),
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: SettingsFlowPalette.error.withValues(alpha: 0.10),
              borderRadius: SettingsFlowTheme.radius(20),
            ),
            child: const Icon(
              Icons.logout_rounded,
              color: SettingsFlowPalette.error,
              size: 28,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Sign out of AvenirDZ?',
            style: SettingsFlowTheme.sectionTitle(),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            'You can sign back in anytime. We just want to make sure this action is intentional.',
            style: SettingsFlowTheme.caption(),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 18),
          SettingsButtonGroup(
            children: [
              SettingsSecondaryButton(
                label: 'Cancel',
                onPressed: () => Navigator.pop(context, false),
              ),
              SettingsPrimaryButton(
                label: 'Sign out',
                backgroundColor: SettingsFlowPalette.error,
                onPressed: () => Navigator.pop(context, true),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
