import 'package:flutter/material.dart';

import '../../l10n/generated/app_localizations.dart';
import '../../widgets/shared/app_content_system.dart';
import '../../widgets/shared/app_logo.dart';
import 'auth_flow_widgets.dart';
import 'company_register_screen.dart';
import 'login_screen.dart';
import 'register_screen.dart';

class RoleChooserScreen extends StatelessWidget {
  const RoleChooserScreen({super.key});

  void _handleBack(BuildContext context) {
    final navigator = Navigator.of(context);
    if (navigator.canPop()) {
      navigator.pop();
      return;
    }

    navigator.pushReplacement(
      MaterialPageRoute<void>(builder: (_) => const LoginScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) {
          return;
        }
        _handleBack(context);
      },
      child: AuthFlowScaffold(
        showBackButton: true,
        onBack: () => _handleBack(context),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 470),
            child: AuthPanelCard(
              padding: const EdgeInsets.all(28),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  const Center(child: AppLogo(height: 44)),
                  const SizedBox(height: 18),
                  AuthCompactHeader(
                    icon: Icons.person_add_rounded,
                    title: l10n.uiJoinFutureGate,
                    subtitle: l10n.uiChooseYourAccountType,
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
                    title: l10n.uiImAStudent,
                    subtitle: l10n.uiOpportunitiesScholarshipsTraining,
                    icon: Icons.school_rounded,
                    color: AuthFlowPalette.orange,
                    showArrow: true,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const RegisterScreen(),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 14),
                  AuthSelectionCard(
                    title: l10n.uiImACompany,
                    subtitle: l10n.uiPublishOpportunities,
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
                    label: l10n.uiBackToLogin,
                    icon: Icons.login_rounded,
                    onPressed: () => _handleBack(context),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
