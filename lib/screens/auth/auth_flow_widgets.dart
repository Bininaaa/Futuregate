import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../widgets/shared/app_content_system.dart';
import '../../widgets/shared/app_logo.dart';

const AppContentTheme authFlowTheme = AppContentTheme(
  accent: Color(0xFF3B22F6),
  accentDark: Color(0xFF1E40AF),
  accentSoft: Color(0xFFE9EEFF),
  secondary: Color(0xFF14B8A6),
  background: Color(0xFFF4F7FB),
  surface: Colors.white,
  surfaceMuted: Color(0xFFF8FAFF),
  border: Color(0xFFDCE3F1),
  textPrimary: Color(0xFF0F172A),
  textSecondary: Color(0xFF475569),
  textMuted: Color(0xFF64748B),
  success: Color(0xFF179D6C),
  warning: Color(0xFFD97706),
  error: Color(0xFFEF4444),
  heroGradient: LinearGradient(
    colors: <Color>[Color(0xFF1E40AF), Color(0xFF3B22F6), Color(0xFF14B8A6)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  ),
  typography: AppContentTypography.innovation,
);

class AuthFlowPalette {
  static const Color orange = Color(0xFFF97316);
  static const Color orangeSoft = Color(0xFFFFEDD5);
  static const Color tealSoft = Color(0xFFE8FFFB);

  const AuthFlowPalette._();
}

class AuthAcademicLevelOption {
  final String value;
  final String label;
  final String description;
  final IconData icon;

  const AuthAcademicLevelOption({
    required this.value,
    required this.label,
    required this.description,
    required this.icon,
  });
}

const List<AuthAcademicLevelOption> authAcademicLevels =
    <AuthAcademicLevelOption>[
      AuthAcademicLevelOption(
        value: 'bac',
        label: 'Bachelor',
        description: 'Foundational university track',
        icon: Icons.school_outlined,
      ),
      AuthAcademicLevelOption(
        value: 'licence',
        label: 'Licence',
        description: 'Licence degree program',
        icon: Icons.menu_book_outlined,
      ),
      AuthAcademicLevelOption(
        value: 'master',
        label: 'Master',
        description: 'Advanced academic specialization',
        icon: Icons.workspace_premium_outlined,
      ),
      AuthAcademicLevelOption(
        value: 'doctorat',
        label: 'Doctorat',
        description: 'Doctoral research and thesis work',
        icon: Icons.science_outlined,
      ),
    ];

AuthAcademicLevelOption authLevelOption(String value) {
  for (final option in authAcademicLevels) {
    if (option.value == value) {
      return option;
    }
  }

  return authAcademicLevels.first;
}

String authAcademicLevelLabel(String value) => authLevelOption(value).label;

class AuthFlowScaffold extends StatelessWidget {
  final Widget child;
  final bool showBackButton;
  final VoidCallback? onBack;
  final Widget? trailing;

  const AuthFlowScaffold({
    super.key,
    required this.child,
    this.showBackButton = false,
    this.onBack,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: DecoratedBox(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: <Color>[
              Color(0xFFF6F9FF),
              Color(0xFFF4F7FB),
              Color(0xFFEDF5FF),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Stack(
          children: <Widget>[
            const Positioned(
              top: -90,
              right: -50,
              child: _AuthGlowOrb(size: 250, color: Color(0x223B22F6)),
            ),
            const Positioned(
              left: -70,
              bottom: -90,
              child: _AuthGlowOrb(size: 230, color: Color(0x2214B8A6)),
            ),
            const Positioned(
              left: 60,
              top: 110,
              child: _AuthGlowOrb(size: 108, color: Color(0x18F97316)),
            ),
            SafeArea(
              child: Column(
                children: <Widget>[
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 10, 20, 6),
                    child: Row(
                      children: <Widget>[
                        if (showBackButton)
                          _AuthTopButton(
                            icon: Icons.arrow_back_rounded,
                            onTap: onBack ?? () => Navigator.of(context).pop(),
                          )
                        else
                          const SizedBox(width: 48),
                        Expanded(
                          child: Center(
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 14,
                                vertical: 8,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.84),
                                borderRadius: BorderRadius.circular(999),
                                border: Border.all(color: authFlowTheme.border),
                              ),
                              child: const AppLogoClear(height: 22),
                            ),
                          ),
                        ),
                        SizedBox(
                          width: 48,
                          child: Align(
                            alignment: Alignment.centerRight,
                            child: trailing,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        return SingleChildScrollView(
                          padding: const EdgeInsets.fromLTRB(20, 10, 20, 28),
                          child: Center(
                            child: ConstrainedBox(
                              constraints: BoxConstraints(
                                maxWidth: 1180,
                                minHeight: constraints.maxHeight - 18,
                              ),
                              child: child,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class AuthSplitLayout extends StatelessWidget {
  final Widget hero;
  final Widget content;
  final int heroFlex;
  final int contentFlex;

  const AuthSplitLayout({
    super.key,
    required this.hero,
    required this.content,
    this.heroFlex = 6,
    this.contentFlex = 5,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth >= 980;

        if (isWide) {
          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Expanded(flex: heroFlex, child: hero),
              const SizedBox(width: 24),
              Expanded(flex: contentFlex, child: content),
            ],
          );
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[hero, const SizedBox(height: 20), content],
        );
      },
    );
  }
}

class AuthHeroMetric {
  final String value;
  final String label;

  const AuthHeroMetric({required this.value, required this.label});
}

class AuthFeaturePoint {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;

  const AuthFeaturePoint({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
  });
}

class AuthHeroPanel extends StatelessWidget {
  final IconData icon;
  final String eyebrow;
  final String title;
  final String subtitle;
  final List<String> chips;
  final List<AuthHeroMetric> metrics;
  final List<AuthFeaturePoint> features;

  const AuthHeroPanel({
    super.key,
    required this.icon,
    required this.eyebrow,
    required this.title,
    required this.subtitle,
    this.chips = const <String>[],
    this.metrics = const <AuthHeroMetric>[],
    this.features = const <AuthFeaturePoint>[],
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        gradient: authFlowTheme.heroGradient,
        borderRadius: BorderRadius.circular(34),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: authFlowTheme.accent.withValues(alpha: 0.14),
            blurRadius: 32,
            offset: const Offset(0, 18),
          ),
        ],
      ),
      child: Stack(
        children: <Widget>[
          Positioned(
            top: -26,
            right: -10,
            child: Container(
              width: 130,
              height: 130,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.08),
                shape: BoxShape.circle,
              ),
            ),
          ),
          Positioned(
            bottom: -48,
            left: -22,
            child: Container(
              width: 170,
              height: 170,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.05),
                shape: BoxShape.circle,
              ),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Row(
                children: <Widget>[
                  Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.16),
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.22),
                      ),
                    ),
                    child: Icon(icon, color: Colors.white, size: 28),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Text(
                      eyebrow.toUpperCase(),
                      style: GoogleFonts.manrope(
                        fontSize: 12,
                        letterSpacing: 1.2,
                        fontWeight: FontWeight.w700,
                        color: Colors.white.withValues(alpha: 0.78),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 22),
              Text(
                title,
                style: GoogleFonts.sora(
                  fontSize: 30,
                  height: 1.08,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 14),
              Text(
                subtitle,
                style: GoogleFonts.manrope(
                  fontSize: 14.4,
                  height: 1.6,
                  fontWeight: FontWeight.w500,
                  color: Colors.white.withValues(alpha: 0.82),
                ),
              ),
              if (chips.isNotEmpty) ...<Widget>[
                const SizedBox(height: 20),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: chips
                      .map(
                        (chip) => Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(999),
                            border: Border.all(
                              color: Colors.white.withValues(alpha: 0.18),
                            ),
                          ),
                          child: Text(
                            chip,
                            style: GoogleFonts.manrope(
                              fontSize: 11.5,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      )
                      .toList(growable: false),
                ),
              ],
              if (metrics.isNotEmpty) ...<Widget>[
                const SizedBox(height: 24),
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: metrics
                      .map(
                        (metric) => Container(
                          constraints: const BoxConstraints(minWidth: 112),
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: Colors.white.withValues(alpha: 0.14),
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: <Widget>[
                              Text(
                                metric.value,
                                style: GoogleFonts.sora(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                metric.label,
                                style: GoogleFonts.manrope(
                                  fontSize: 11.5,
                                  height: 1.45,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white.withValues(alpha: 0.74),
                                ),
                              ),
                            ],
                          ),
                        ),
                      )
                      .toList(growable: false),
                ),
              ],
              if (features.isNotEmpty) ...<Widget>[
                const SizedBox(height: 24),
                ...features.map(
                  (feature) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.14),
                        ),
                      ),
                      child: Row(
                        children: <Widget>[
                          Container(
                            width: 42,
                            height: 42,
                            decoration: BoxDecoration(
                              color: feature.color.withValues(alpha: 0.18),
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: Icon(
                              feature.icon,
                              color: Colors.white,
                              size: 20,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: <Widget>[
                                Text(
                                  feature.title,
                                  style: GoogleFonts.sora(
                                    fontSize: 13.4,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.white,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  feature.subtitle,
                                  style: GoogleFonts.manrope(
                                    fontSize: 11.8,
                                    height: 1.45,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.white.withValues(alpha: 0.74),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

class AuthPanelCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;

  const AuthPanelCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(24),
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: <Color>[
            authFlowTheme.surface.withValues(alpha: 0.98),
            authFlowTheme.surfaceMuted.withValues(alpha: 0.94),
          ],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: authFlowTheme.border.withValues(alpha: 0.9)),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: authFlowTheme.accent.withValues(alpha: 0.07),
            blurRadius: 28,
            offset: const Offset(0, 16),
          ),
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.035),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: child,
    );
  }
}

class AuthSectionHeading extends StatelessWidget {
  final String title;
  final String subtitle;

  const AuthSectionHeading({
    super.key,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(title, style: authFlowTheme.section(size: 20.5)),
        const SizedBox(height: 8),
        Text(
          subtitle,
          style: authFlowTheme.body(
            size: 12.9,
            color: authFlowTheme.textSecondary,
          ),
        ),
      ],
    );
  }
}

class AuthStickerSpec {
  final IconData icon;
  final Color color;

  const AuthStickerSpec({required this.icon, required this.color});
}

class AuthCompactHeader extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final List<String> badges;
  final List<AuthStickerSpec> stickers;

  const AuthCompactHeader({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    this.badges = const <String>[],
    this.stickers = const <AuthStickerSpec>[],
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: <Widget>[
        SizedBox(
          width: 170,
          height: 96,
          child: Stack(
            clipBehavior: Clip.none,
            children: <Widget>[
              Align(
                child: Container(
                  width: 70,
                  height: 70,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: <Color>[
                        authFlowTheme.accent,
                        authFlowTheme.accentDark,
                        AuthFlowPalette.orange,
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(22),
                    boxShadow: <BoxShadow>[
                      BoxShadow(
                        color: authFlowTheme.accent.withValues(alpha: 0.18),
                        blurRadius: 22,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: Icon(icon, color: Colors.white, size: 31),
                ),
              ),
              if (stickers.isNotEmpty)
                Positioned(
                  left: 14,
                  top: 10,
                  child: _AuthStickerBubble(sticker: stickers[0]),
                ),
              if (stickers.length > 1)
                Positioned(
                  right: 14,
                  top: 4,
                  child: _AuthStickerBubble(sticker: stickers[1]),
                ),
              if (stickers.length > 2)
                Positioned(
                  right: 28,
                  bottom: 0,
                  child: _AuthStickerBubble(sticker: stickers[2]),
                ),
              if (stickers.length > 3)
                Positioned(
                  left: 28,
                  bottom: 4,
                  child: _AuthStickerBubble(sticker: stickers[3]),
                ),
            ],
          ),
        ),
        const SizedBox(height: 10),
        Text(
          title,
          textAlign: TextAlign.center,
          style: authFlowTheme.headline(
            size: 24.8,
            color: authFlowTheme.textPrimary,
            weight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 6),
        ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 470),
          child: Text(
            subtitle,
            textAlign: TextAlign.center,
            style: authFlowTheme.body(
              size: 12.5,
              color: authFlowTheme.textSecondary,
              weight: FontWeight.w600,
            ),
          ),
        ),
        if (badges.isNotEmpty) ...<Widget>[
          const SizedBox(height: 14),
          Wrap(
            alignment: WrapAlignment.center,
            spacing: 8,
            runSpacing: 8,
            children: badges
                .map(
                  (badge) => Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 7,
                    ),
                    decoration: BoxDecoration(
                      color: authFlowTheme.surfaceMuted.withValues(alpha: 0.95),
                      borderRadius: BorderRadius.circular(999),
                      border: Border.all(color: authFlowTheme.border),
                    ),
                    child: Text(
                      badge,
                      style: authFlowTheme.label(
                        size: 10.9,
                        color: authFlowTheme.textPrimary,
                      ),
                    ),
                  ),
                )
                .toList(growable: false),
          ),
        ],
      ],
    );
  }
}

class _AuthStickerBubble extends StatelessWidget {
  final AuthStickerSpec sticker;

  const _AuthStickerBubble({required this.sticker});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 34,
      height: 34,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.96),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: authFlowTheme.border),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: sticker.color.withValues(alpha: 0.16),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Icon(sticker.icon, color: sticker.color, size: 18),
    );
  }
}

class AuthTextField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final String hint;
  final IconData icon;
  final TextInputType keyboardType;
  final bool obscureText;
  final Widget? suffixIcon;
  final String? Function(String?)? validator;
  final int maxLines;
  final int minLines;
  final bool readOnly;
  final ValueChanged<String>? onChanged;
  final TextInputAction? textInputAction;
  final VoidCallback? onTap;
  final Iterable<String>? autofillHints;
  final ValueChanged<String>? onFieldSubmitted;

  const AuthTextField({
    super.key,
    required this.controller,
    required this.label,
    required this.hint,
    required this.icon,
    this.keyboardType = TextInputType.text,
    this.obscureText = false,
    this.suffixIcon,
    this.validator,
    this.maxLines = 1,
    this.minLines = 1,
    this.readOnly = false,
    this.onChanged,
    this.textInputAction,
    this.onTap,
    this.autofillHints,
    this.onFieldSubmitted,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          label,
          style: authFlowTheme.label(
            size: 12.1,
            color: authFlowTheme.textPrimary,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          obscureText: obscureText,
          validator: validator,
          maxLines: maxLines,
          minLines: minLines,
          readOnly: readOnly,
          onChanged: onChanged,
          onTap: onTap,
          autofillHints: autofillHints,
          textInputAction: textInputAction,
          onFieldSubmitted: onFieldSubmitted,
          style: authFlowTheme.body(
            size: 13.4,
            color: authFlowTheme.textPrimary,
            weight: FontWeight.w600,
          ),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: authFlowTheme.body(
              size: 12.6,
              color: authFlowTheme.textMuted,
            ),
            prefixIcon: Icon(icon, size: 20, color: authFlowTheme.textMuted),
            suffixIcon: suffixIcon,
            filled: true,
            fillColor: authFlowTheme.surfaceMuted,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 18,
              vertical: 16,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(20),
              borderSide: BorderSide(color: authFlowTheme.border),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(20),
              borderSide: BorderSide(color: authFlowTheme.border),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(20),
              borderSide: BorderSide(color: authFlowTheme.accent, width: 1.4),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(20),
              borderSide: BorderSide(color: authFlowTheme.error),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(20),
              borderSide: BorderSide(color: authFlowTheme.error, width: 1.4),
            ),
          ),
        ),
      ],
    );
  }
}

class AuthGoogleButton extends StatelessWidget {
  final VoidCallback? onPressed;

  const AuthGoogleButton({super.key, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(18),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.025),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: SizedBox(
        width: double.infinity,
        height: 54,
        child: OutlinedButton(
          onPressed: onPressed,
          style: OutlinedButton.styleFrom(
            foregroundColor: authFlowTheme.textPrimary,
            backgroundColor: Colors.white,
            side: BorderSide(
              color: authFlowTheme.border.withValues(alpha: 0.9),
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(18),
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFF),
                  borderRadius: BorderRadius.circular(9),
                ),
                child: Center(
                  child: Text(
                    'G',
                    style: GoogleFonts.sora(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF4285F4),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Text(
                'Continue with Google',
                style: GoogleFonts.manrope(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: authFlowTheme.textPrimary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class AuthDivider extends StatelessWidget {
  final String label;

  const AuthDivider({super.key, this.label = 'OR'});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: <Widget>[
        Expanded(child: Divider(color: authFlowTheme.border)),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Text(
            label,
            style: GoogleFonts.manrope(
              fontSize: 11.5,
              fontWeight: FontWeight.w700,
              color: authFlowTheme.textMuted,
              letterSpacing: 0.5,
            ),
          ),
        ),
        Expanded(child: Divider(color: authFlowTheme.border)),
      ],
    );
  }
}

class AuthSelectionCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final VoidCallback? onTap;
  final bool selected;
  final Color color;
  final bool showArrow;

  const AuthSelectionCard({
    super.key,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.onTap,
    this.selected = false,
    this.color = AuthFlowPalette.orange,
    this.showArrow = false,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(24),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: selected ? color.withValues(alpha: 0.08) : Colors.white,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: selected ? color : authFlowTheme.border,
              width: selected ? 1.5 : 1,
            ),
            boxShadow: selected
                ? <BoxShadow>[
                    BoxShadow(
                      color: color.withValues(alpha: 0.14),
                      blurRadius: 26,
                      offset: const Offset(0, 14),
                    ),
                  ]
                : authFlowTheme.shadow(0.025),
          ),
          child: Row(
            children: <Widget>[
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: selected
                      ? color.withValues(alpha: 0.15)
                      : authFlowTheme.surfaceMuted,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(
                  icon,
                  color: selected ? color : authFlowTheme.textMuted,
                  size: 24,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      title,
                      style: GoogleFonts.sora(
                        fontSize: 14.2,
                        fontWeight: FontWeight.w600,
                        color: authFlowTheme.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      subtitle,
                      style: authFlowTheme.body(
                        size: 11.8,
                        color: authFlowTheme.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              if (showArrow)
                Icon(Icons.arrow_forward_rounded, color: color)
              else
                Icon(
                  selected
                      ? Icons.check_circle_rounded
                      : Icons.radio_button_unchecked_rounded,
                  color: selected ? color : authFlowTheme.textMuted,
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class AuthProgressStrip extends StatelessWidget {
  final int step;
  final int total;
  final String label;

  const AuthProgressStrip({
    super.key,
    required this.step,
    required this.total,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    final safeTotal = total <= 0 ? 1 : total;
    final progress = (step / safeTotal).clamp(0.0, 1.0);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: authFlowTheme.surfaceMuted,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: authFlowTheme.border),
      ),
      child: Row(
        children: <Widget>[
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
            decoration: BoxDecoration(
              color: authFlowTheme.accentSoft,
              borderRadius: BorderRadius.circular(999),
            ),
            child: Text(
              'Step $step of $total',
              style: authFlowTheme.label(
                size: 11.2,
                color: authFlowTheme.accent,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(999),
              child: LinearProgressIndicator(
                value: progress,
                minHeight: 6,
                backgroundColor: authFlowTheme.border,
                color: authFlowTheme.accent,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Flexible(
            child: Text(
              label,
              textAlign: TextAlign.right,
              style: authFlowTheme.body(
                size: 11.8,
                color: authFlowTheme.textSecondary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class AuthReadOnlyTile extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final int maxLines;

  const AuthReadOnlyTile({
    super.key,
    required this.label,
    required this.value,
    required this.icon,
    this.maxLines = 1,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: authFlowTheme.surfaceMuted,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: authFlowTheme.border),
      ),
      child: Row(
        children: <Widget>[
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: authFlowTheme.accentSoft,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: authFlowTheme.accent, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  label,
                  style: authFlowTheme.label(
                    size: 11,
                    color: authFlowTheme.textMuted,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  maxLines: maxLines,
                  overflow: TextOverflow.ellipsis,
                  softWrap: false,
                  style: authFlowTheme.body(
                    size: 13,
                    color: authFlowTheme.textPrimary,
                    weight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _AuthTopButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _AuthTopButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Ink(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.92),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: authFlowTheme.border),
          ),
          child: Icon(icon, color: authFlowTheme.textPrimary),
        ),
      ),
    );
  }
}

class _AuthGlowOrb extends StatelessWidget {
  final double size;
  final Color color;

  const _AuthGlowOrb({required this.size, required this.color});

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(color: color, shape: BoxShape.circle),
      ),
    );
  }
}
