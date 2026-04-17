import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../providers/auth_provider.dart';
import '../../widgets/app_shell_background.dart';
import '../../widgets/profile_avatar.dart';
import '../../widgets/shared/app_loading.dart';
import '../settings/logout_confirmation_sheet.dart';
import 'profile_screen.dart';

class CompanyApprovalStatusScreen extends StatelessWidget {
  const CompanyApprovalStatusScreen({super.key});

  static const Color _ink = Color(0xFF112243);
  static const Color _muted = Color(0xFF5F6F89);
  static const Color _primary = Color(0xFF1D4ED8);
  static const Color _pending = Color(0xFFF59E0B);
  static const Color _danger = Color(0xFFDC2626);
  static const Color _success = Color(0xFF16A34A);

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final user = auth.userModel;

    if (user == null) {
      return const AppShellBackground(
        child: Scaffold(
          backgroundColor: Colors.transparent,
          body: SafeArea(
            child: AppLoadingView(density: AppLoadingDensity.compact),
          ),
        ),
      );
    }

    final isRejected = user.isCompanyRejected;
    final accent = isRejected ? _danger : _pending;
    final title = isRejected
        ? 'Company Review Needs Attention'
        : 'Company Review In Progress';
    final subtitle = isRejected
        ? 'Your company account has not been approved yet. Review your profile and commercial register, then update anything that needs correction before trying again.'
        : 'Your company account has been created successfully. An administrator still needs to review your commercial register before your workspace goes live.';
    final badgeLabel = isRejected ? 'REJECTED' : 'PENDING REVIEW';
    final helperTitle = isRejected
        ? 'What to fix before the next review'
        : 'What happens next';
    final helperItems = isRejected
        ? const <String>[
            'Check your company details and commercial register document.',
            'Update anything incomplete or unclear from your company profile.',
            'Once the admin reviews it again, access will open automatically.',
          ]
        : const <String>[
            'The admin team reviews the company profile and uploaded register.',
            'Your workspace will unlock automatically as soon as the company is approved.',
            'You can still open your profile now and improve the information before approval.',
          ];

    return AppShellBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: Stack(
          children: [
            Positioned(
              top: -110,
              right: -80,
              child: _BackdropOrb(
                size: 240,
                color: accent.withValues(alpha: 0.14),
              ),
            ),
            const Positioned(
              bottom: -90,
              left: -60,
              child: _BackdropOrb(size: 220, color: Color(0x121D4ED8)),
            ),
            SafeArea(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 28),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Container(
                        width: 96,
                        height: 96,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [accent, accent.withValues(alpha: 0.72)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(30),
                          boxShadow: [
                            BoxShadow(
                              color: accent.withValues(alpha: 0.22),
                              blurRadius: 32,
                              offset: const Offset(0, 18),
                            ),
                          ],
                        ),
                        child: Icon(
                          isRejected
                              ? Icons.rule_folder_outlined
                              : Icons.pending_actions_rounded,
                          size: 42,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    const SizedBox(height: 22),
                    _Panel(
                      padding: const EdgeInsets.fromLTRB(22, 22, 22, 20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 8,
                                  ),
                                  decoration: BoxDecoration(
                                    color: accent.withValues(alpha: 0.10),
                                    borderRadius: BorderRadius.circular(999),
                                  ),
                                  child: Text(
                                    badgeLabel,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: GoogleFonts.poppins(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w700,
                                      letterSpacing: 0.5,
                                      color: accent,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Container(
                                padding: const EdgeInsets.all(3),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(18),
                                  border: Border.all(
                                    color: accent.withValues(alpha: 0.10),
                                  ),
                                ),
                                child: ProfileAvatar(user: user, radius: 21),
                              ),
                            ],
                          ),
                          const SizedBox(height: 18),
                          Text(
                            title,
                            style: GoogleFonts.poppins(
                              fontSize: 24,
                              fontWeight: FontWeight.w700,
                              color: _ink,
                              height: 1.15,
                            ),
                          ),
                          const SizedBox(height: 10),
                          Text(
                            subtitle,
                            style: GoogleFonts.poppins(
                              fontSize: 13.5,
                              height: 1.7,
                              color: _muted,
                            ),
                          ),
                          const SizedBox(height: 18),
                          Row(
                            children: [
                              Expanded(
                                child: _InfoStat(
                                  label: 'Company',
                                  value:
                                      (user.companyName ?? user.fullName)
                                          .trim()
                                          .isEmpty
                                      ? 'Not set'
                                      : (user.companyName ?? user.fullName)
                                            .trim(),
                                  color: _primary,
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: _InfoStat(
                                  label: 'Register',
                                  value: user.hasCommercialRegister
                                      ? 'Uploaded'
                                      : 'Missing',
                                  color: user.hasCommercialRegister
                                      ? _success
                                      : _danger,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    _Panel(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            helperTitle,
                            style: GoogleFonts.poppins(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: _ink,
                            ),
                          ),
                          const SizedBox(height: 14),
                          for (final item in helperItems) ...[
                            _HelperRow(text: item, color: accent),
                            if (item != helperItems.last)
                              const SizedBox(height: 12),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    _Panel(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Need to review your profile?',
                            style: GoogleFonts.poppins(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: _ink,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'You can open the company profile right now to improve the company story, website, phone number, logo, or commercial register while the account is waiting for review.',
                            style: GoogleFonts.poppins(
                              fontSize: 13,
                              height: 1.65,
                              color: _muted,
                            ),
                          ),
                          const SizedBox(height: 18),
                          FilledButton.icon(
                            onPressed: () {
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (_) => const CompanyProfileScreen(),
                                ),
                              );
                            },
                            icon: const Icon(Icons.open_in_new_rounded),
                            label: Text(
                              isRejected
                                  ? 'Update Company Profile'
                                  : 'Open Company Profile',
                            ),
                            style: FilledButton.styleFrom(
                              minimumSize: const Size(double.infinity, 52),
                              backgroundColor: _primary,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(18),
                              ),
                            ),
                          ),
                          const SizedBox(height: 10),
                          OutlinedButton.icon(
                            onPressed: () =>
                                showLogoutConfirmationSheet(context),
                            icon: const Icon(Icons.logout_rounded),
                            label: const Text('Sign out'),
                            style: OutlinedButton.styleFrom(
                              minimumSize: const Size(double.infinity, 52),
                              foregroundColor: _ink,
                              side: BorderSide(
                                color: _ink.withValues(alpha: 0.12),
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(18),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Panel extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;

  const _Panel({required this.child, this.padding = const EdgeInsets.all(20)});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: padding,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: const Color(0xFFE4EBF3)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 28,
            offset: const Offset(0, 16),
          ),
        ],
      ),
      child: child,
    );
  }
}

class _InfoStat extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _InfoStat({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: GoogleFonts.poppins(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            value,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.poppins(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF112243),
              height: 1.35,
            ),
          ),
        ],
      ),
    );
  }
}

class _HelperRow extends StatelessWidget {
  final String text;
  final Color color;

  const _HelperRow({required this.text, required this.color});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 34,
          height: 34,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.10),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(Icons.check_rounded, color: color, size: 18),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            text,
            style: GoogleFonts.poppins(
              fontSize: 13,
              height: 1.6,
              color: const Color(0xFF5F6F89),
            ),
          ),
        ),
      ],
    );
  }
}

class _BackdropOrb extends StatelessWidget {
  final double size;
  final Color color;

  const _BackdropOrb({required this.size, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(shape: BoxShape.circle, color: color),
    );
  }
}
