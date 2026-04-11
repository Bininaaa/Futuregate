import 'package:flutter/material.dart';

import '../../widgets/shared/app_content_system.dart';
import 'auth_flow_widgets.dart';
import 'company_register_screen.dart';
import 'register_screen.dart';

class RoleChooserScreen extends StatelessWidget {
  const RoleChooserScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return AuthFlowScaffold(
      showBackButton: true,
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 470),
          child: AuthPanelCard(
            padding: const EdgeInsets.all(28),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                const AuthCompactHeader(
                  icon: Icons.person_add_rounded,
                  title: 'Join FutureGate',
                  subtitle: 'Choose your account type.',
                  stickers: <AuthStickerSpec>[
                    AuthStickerSpec(
                      icon: Icons.school_rounded,
                      color: AuthFlowPalette.orange,
                    ),
                    AuthStickerSpec(
                      icon: Icons.business_center_rounded,
                      color: Color(0xFF14B8A6),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                AuthSelectionCard(
                  title: 'I\'m a Student',
                  subtitle: 'Opportunities, scholarships, training',
                  icon: Icons.school_rounded,
                  color: AuthFlowPalette.orange,
                  showArrow: true,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const RegisterScreen()),
                    );
                  },
                ),
                const SizedBox(height: 14),
                AuthSelectionCard(
                  title: 'I\'m a Company',
                  subtitle: 'Publish opportunities',
                  icon: Icons.business_center_rounded,
                  color: authFlowTheme.secondary,
                  showArrow: true,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const CompanyRegisterScreen(),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 18),
                AppSecondaryButton(
                  theme: authFlowTheme,
                  label: 'Back to Login',
                  icon: Icons.login_rounded,
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
