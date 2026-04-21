import 'dart:async';
import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/auth_provider.dart';
import '../../services/app_intro_preferences_service.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_typography.dart';
import '../../widgets/shared/app_logo.dart';
import '../auth/login_screen.dart';
import '../auth/role_chooser_screen.dart';
import '../auth_wrapper.dart';

class GetStartedScreen extends StatefulWidget {
  final AppIntroPreferencesService? introPreferencesService;

  const GetStartedScreen({super.key, this.introPreferencesService});

  @override
  State<GetStartedScreen> createState() => _GetStartedScreenState();
}

class _GetStartedScreenState extends State<GetStartedScreen> {
  static const List<_SlideSpec> _slides = <_SlideSpec>[
    _SlideSpec(
      layout: _HeroLayout.connect,
      assetPath: 'assets/pictures/get_started1.png',
      heroHeight: 500,
      sheetHeight: 312,
      sheetOffset: 58,
      indicatorAlignment: MainAxisAlignment.start,
      titleParts: <_TitlePart>[
        _TitlePart(text: 'Connect with the '),
        _TitlePart(text: 'Right\nOpportunities.', highlight: true),
      ],
      description:
          'Reach companies, explore real career paths, and take the next step toward your future.',
      titleAlign: TextAlign.left,
      bodyAlign: CrossAxisAlignment.start,
    ),
    _SlideSpec(
      layout: _HeroLayout.profile,
      assetPath: AppBrandAssets.getStartedProfile,
      heroHeight: 478,
      sheetHeight: 312,
      sheetOffset: 46,
      indicatorAlignment: MainAxisAlignment.center,
      titleParts: <_TitlePart>[
        _TitlePart(text: 'Build a Strong Student\nProfile.'),
      ],
      description:
          'Create your profile, showcase your skills, and prepare for the opportunities that match your goals.',
      titleAlign: TextAlign.left,
      bodyAlign: CrossAxisAlignment.start,
    ),
    _SlideSpec(
      layout: _HeroLayout.future,
      assetPath: 'assets/pictures/get_started2.png',
      heroHeight: 492,
      sheetHeight: 312,
      sheetOffset: 52,
      indicatorAlignment: MainAxisAlignment.center,
      titleParts: <_TitlePart>[
        _TitlePart(text: 'Open the Door to Your\nFuture.'),
      ],
      description:
          'Build your FutureGate space to apply faster, track replies, and keep internships, jobs, and scholarships organized.',
      titleAlign: TextAlign.center,
      bodyAlign: CrossAxisAlignment.center,
    ),
  ];

  late final AppIntroPreferencesService _introPreferencesService;
  late final PageController _pageController;

  int _currentIndex = 0;
  bool _isMarkingSeen = false;

  @override
  void initState() {
    super.initState();
    _introPreferencesService =
        widget.introPreferencesService ?? AppIntroPreferencesService();
    _pageController = PageController();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _markSeen() async {
    if (_isMarkingSeen) {
      return;
    }

    _isMarkingSeen = true;
    try {
      await _introPreferencesService.markGetStartedSeen();
    } catch (_) {
      // Keep onboarding usable even if persistence is unavailable.
    } finally {
      _isMarkingSeen = false;
    }
  }

  Future<void> _handlePageChanged(int index) async {
    if (!mounted) {
      return;
    }

    setState(() => _currentIndex = index);
    if (index == _slides.length - 1) {
      unawaited(_markSeen());
    }
  }

  Future<void> _goToPage(int index) async {
    final reduceMotion =
        WidgetsBinding
            .instance
            .platformDispatcher
            .accessibilityFeatures
            .disableAnimations ||
        (MediaQuery.maybeOf(context)?.accessibleNavigation ?? false);

    if (reduceMotion) {
      _pageController.jumpToPage(index);
      return;
    }

    await _pageController.animateToPage(
      index,
      duration: const Duration(milliseconds: 260),
      curve: Curves.easeOutCubic,
    );
  }

  Future<void> _goNext() async {
    if (_currentIndex >= _slides.length - 1) {
      return;
    }
    await _goToPage(_currentIndex + 1);
  }

  Future<void> _goBack() async {
    if (_currentIndex == 0) {
      return;
    }
    await _goToPage(_currentIndex - 1);
  }

  Future<void> _skip() async {
    await _markSeen();
    if (!mounted) {
      return;
    }
    _replaceWith(const AuthWrapper());
  }

  Future<void> _openCreateAccount() async {
    await _markSeen();
    if (!mounted) {
      return;
    }
    _replaceWith(const RoleChooserScreen());
  }

  Future<void> _openLogin() async {
    await _markSeen();
    if (!mounted) {
      return;
    }
    _replaceWith(const LoginScreen());
  }

  Future<void> _continueToApp() async {
    await _markSeen();
    if (!mounted) {
      return;
    }
    _replaceWith(const AuthWrapper());
  }

  void _replaceWith(Widget screen) {
    Navigator.of(context).pushReplacement(
      PageRouteBuilder<void>(
        pageBuilder: (_, _, _) => screen,
        transitionDuration: const Duration(milliseconds: 240),
        transitionsBuilder: (_, animation, _, child) =>
            FadeTransition(opacity: animation, child: child),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isSignedIn = context.watch<AuthProvider>().userModel != null;
    final colors = AppColors.of(context);

    return Scaffold(
      backgroundColor: colors.background,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final width = math.min(constraints.maxWidth, 440.0);

            return Center(
              child: SizedBox(
                width: width,
                child: Stack(
                  children: <Widget>[
                    Positioned.fill(
                      child: PageView.builder(
                        controller: _pageController,
                        itemCount: _slides.length,
                        onPageChanged: (index) => _handlePageChanged(index),
                        itemBuilder: (context, index) {
                          final slide = _slides[index];
                          return _SlideView(
                            spec: slide,
                            index: index,
                            totalSlides: _slides.length,
                            isLastSlide: index == _slides.length - 1,
                            isSignedIn: isSignedIn,
                            pageController: _pageController,
                            onPrimaryAction: _goNext,
                            onForward: index == _slides.length - 1
                                ? (isSignedIn
                                      ? _continueToApp
                                      : _openCreateAccount)
                                : _goNext,
                            onBack: _goBack,
                            onLogin: _openLogin,
                          );
                        },
                      ),
                    ),
                    Positioned(
                      top: 10,
                      right: 16,
                      child: TextButton(
                        key: const ValueKey<String>('onboarding_skip_button'),
                        onPressed: _skip,
                        style: TextButton.styleFrom(
                          foregroundColor: colors.textMuted,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 6,
                          ),
                        ),
                        child: Text(
                          'Skip',
                          style: AppTypography.product(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: colors.textMuted,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _SlideView extends StatelessWidget {
  final _SlideSpec spec;
  final int index;
  final int totalSlides;
  final bool isLastSlide;
  final bool isSignedIn;
  final PageController pageController;
  final Future<void> Function() onPrimaryAction;
  final Future<void> Function() onForward;
  final Future<void> Function() onBack;
  final Future<void> Function() onLogin;

  const _SlideView({
    required this.spec,
    required this.index,
    required this.totalSlides,
    required this.isLastSlide,
    required this.isSignedIn,
    required this.pageController,
    required this.onPrimaryAction,
    required this.onForward,
    required this.onBack,
    required this.onLogin,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final preferredHeight =
            spec.heroHeight + spec.sheetHeight - spec.sheetOffset;
        final heroScale = math.min(
          constraints.maxHeight / preferredHeight,
          1.0,
        );
        final scaledHeroHeight = spec.heroHeight * heroScale;
        final scaledSheetTop = (spec.heroHeight - spec.sheetOffset) * heroScale;
        final scaledSheetHeight = constraints.maxHeight - scaledSheetTop;
        final scaledWidth = constraints.maxWidth / heroScale;
        final reduceMotion =
            WidgetsBinding
                .instance
                .platformDispatcher
                .accessibilityFeatures
                .disableAnimations ||
            (MediaQuery.maybeOf(context)?.accessibleNavigation ?? false);

        return AnimatedBuilder(
          animation: pageController,
          builder: (context, _) {
            final currentPage = pageController.hasClients
                ? (pageController.page ?? pageController.initialPage.toDouble())
                : pageController.initialPage.toDouble();
            final pageDelta = (currentPage - index).clamp(-1.0, 1.0).toDouble();
            final activeProgress = 1 - pageDelta.abs();
            final heroTranslate = reduceMotion ? 0.0 : pageDelta * -28;
            final sheetTranslate = reduceMotion ? 0.0 : pageDelta * -14;
            final heroVisualScale = reduceMotion
                ? 1.0
                : 0.96 + (activeProgress * 0.04);
            final sheetVisualScale = reduceMotion
                ? 1.0
                : 0.985 + (activeProgress * 0.015);
            final heroOpacity = reduceMotion
                ? 1.0
                : 0.78 + (activeProgress * 0.22);
            final sheetOpacity = reduceMotion
                ? 1.0
                : 0.9 + (activeProgress * 0.1);

            return SizedBox(
              height: constraints.maxHeight,
              child: Stack(
                clipBehavior: Clip.none,
                children: <Widget>[
                  Positioned(
                    top: 0,
                    left: 0,
                    right: 0,
                    height: scaledHeroHeight,
                    child: Align(
                      alignment: Alignment.topCenter,
                      child: Opacity(
                        opacity: heroOpacity,
                        child: Transform.translate(
                          offset: Offset(heroTranslate, 0),
                          child: Transform.scale(
                            scale: heroScale * heroVisualScale,
                            alignment: Alignment.topCenter,
                            child: SizedBox(
                              width: scaledWidth,
                              height: spec.heroHeight,
                              child: _HeroStage(spec: spec),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    top: scaledSheetTop,
                    left: 0,
                    right: 0,
                    height: scaledSheetHeight,
                    child: Opacity(
                      opacity: sheetOpacity,
                      child: Transform.translate(
                        offset: Offset(sheetTranslate, 0),
                        child: Transform.scale(
                          scale: sheetVisualScale,
                          alignment: Alignment.topCenter,
                          child: _BottomSheetStage(
                            spec: spec,
                            index: index,
                            totalSlides: totalSlides,
                            isLastSlide: isLastSlide,
                            isSignedIn: isSignedIn,
                            onPrimaryAction: onPrimaryAction,
                            onForward: onForward,
                            onBack: onBack,
                            onLogin: onLogin,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}

class _HeroStage extends StatelessWidget {
  static const Color _primary = Color(0xFF3424F5);
  static const Color _ink = Color(0xFF0F1D3A);
  static const Color _mint = Color(0xFF66E8D6);
  static const Color _deepTeal = Color(0xFF05756B);
  static const Color _shell = Color(0xFFF7F8FE);

  final _SlideSpec spec;

  const _HeroStage({required this.spec});

  @override
  Widget build(BuildContext context) {
    switch (spec.layout) {
      case _HeroLayout.connect:
        return _buildConnectHero();
      case _HeroLayout.profile:
        return _buildProfileHero();
      case _HeroLayout.future:
        return _buildFutureHero();
    }
  }

  Widget _buildConnectHero() {
    return SizedBox(
      height: spec.heroHeight,
      child: Stack(
        children: <Widget>[
          Positioned.fill(
            child: Stack(
              fit: StackFit.expand,
              children: <Widget>[
                Image.asset(
                  spec.assetPath,
                  fit: BoxFit.cover,
                  alignment: const Alignment(0.28, -0.08),
                  filterQuality: FilterQuality.high,
                ),
                const DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: <Color>[
                        Color(0x1807112E),
                        Color(0x0007112E),
                        Color(0xC808122A),
                      ],
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Positioned(
            top: 116,
            right: 18,
            child: SizedBox(
              width: 198,
              child: Opacity(
                opacity: 0.82,
                child: _GlassCard(
                  padding: const EdgeInsets.fromLTRB(15, 14, 15, 13),
                  borderRadius: 28,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      Row(
                        children: <Widget>[
                          Container(
                            width: 36,
                            height: 36,
                            decoration: const BoxDecoration(
                              color: _mint,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.verified_rounded,
                              color: _deepTeal,
                              size: 20,
                            ),
                          ),
                          const SizedBox(width: 9),
                          Expanded(
                            child: Text(
                              'Application\nApproved',
                              style: AppTypography.product(
                                fontSize: 14.4,
                                fontWeight: FontWeight.w800,
                                color: const Color(0xFF102040),
                                height: 1.16,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(999),
                        child: const LinearProgressIndicator(
                          value: 1,
                          minHeight: 7,
                          backgroundColor: Color(0xFFD8E0EC),
                          valueColor: AlwaysStoppedAnimation<Color>(_deepTeal),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          Positioned(
            left: 16,
            right: 124,
            bottom: 18,
            child: _GlassCard(
              padding: const EdgeInsets.fromLTRB(15, 15, 15, 13),
              borderRadius: 30,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  Row(
                    children: <Widget>[
                      CircleAvatar(
                        radius: 19,
                        backgroundColor: const Color(0xFFDAE4F6),
                        child: Icon(
                          Icons.person_rounded,
                          color: _primary.withValues(alpha: 0.88),
                          size: 22,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            Text(
                              'Alex from TechCorp',
                              style: AppTypography.product(
                                fontSize: 12.5,
                                fontWeight: FontWeight.w800,
                                color: const Color(0xFF102040),
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '"We\'d love to chat about..."',
                              style: AppTypography.product(
                                fontSize: 10.8,
                                fontWeight: FontWeight.w600,
                                color: const Color(0xFF5E6A82),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Container(
                    width: double.infinity,
                    height: 40,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(24),
                      gradient: const LinearGradient(
                        colors: <Color>[Color(0xFF260EDC), _primary],
                      ),
                      boxShadow: <BoxShadow>[
                        BoxShadow(
                          color: _primary.withValues(alpha: 0.2),
                          blurRadius: 18,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: Center(
                      child: Text(
                        'Reply Now',
                        style: AppTypography.product(
                          fontSize: 13.2,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileHero() {
    return SizedBox(
      height: spec.heroHeight,
      child: Stack(
        children: <Widget>[
          Positioned.fill(
            child: DecoratedBox(
              decoration: const BoxDecoration(color: _shell),
              child: Stack(
                children: <Widget>[
                  Positioned(
                    top: 18,
                    left: -110,
                    child: _GlowBlob(
                      size: 260,
                      color: _mint.withValues(alpha: 0.16),
                    ),
                  ),
                  Positioned(
                    top: -20,
                    right: -50,
                    child: _GlowBlob(
                      size: 220,
                      color: _primary.withValues(alpha: 0.08),
                    ),
                  ),
                ],
              ),
            ),
          ),
          Positioned(
            top: 54,
            left: 20,
            right: 150,
            child: _GlassCard(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 14),
              borderRadius: 28,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Row(
                    children: <Widget>[
                      CircleAvatar(
                        radius: 21,
                        backgroundColor: const Color(0xFFDAE4F6),
                        child: const Icon(
                          Icons.person_outline_rounded,
                          color: _ink,
                          size: 23,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          children: <Widget>[
                            Container(
                              height: 10,
                              decoration: BoxDecoration(
                                color: const Color(0xFFDCE7FA),
                                borderRadius: BorderRadius.circular(999),
                              ),
                            ),
                            const SizedBox(height: 8),
                            Container(
                              height: 8,
                              width: 78,
                              alignment: Alignment.centerLeft,
                              decoration: BoxDecoration(
                                color: const Color(0xFFDCE7FA),
                                borderRadius: BorderRadius.circular(999),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Row(
                    children: <Widget>[
                      Expanded(
                        child: Text(
                          'Profile Strength',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppTypography.product(
                            fontSize: 13.5,
                            fontWeight: FontWeight.w700,
                            color: _ink,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '85%',
                        style: AppTypography.product(
                          fontSize: 13.5,
                          fontWeight: FontWeight.w800,
                          color: _deepTeal,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(999),
                    child: const LinearProgressIndicator(
                      value: 0.85,
                      minHeight: 9,
                      backgroundColor: Color(0xFFDDE4EF),
                      valueColor: AlwaysStoppedAnimation<Color>(_deepTeal),
                    ),
                  ),
                ],
              ),
            ),
          ),
          Positioned(
            top: 76,
            right: 20,
            child: _GlassCard(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
              borderRadius: 24,
              child: SizedBox(
                width: 88,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    Container(
                      width: 44,
                      height: 44,
                      decoration: const BoxDecoration(
                        color: _mint,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.description_rounded,
                        size: 21,
                        color: _deepTeal,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'Resume.pdf',
                      textAlign: TextAlign.center,
                      style: AppTypography.product(
                        fontSize: 11.6,
                        fontWeight: FontWeight.w700,
                        color: _ink,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            left: 18,
            right: 18,
            top: 192,
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: const <Widget>[
                _SkillChip(label: 'Product Design', primary: true),
                _SkillChip(label: 'Strategic Thinking', filled: true),
                _SkillChip(label: 'Public Speaking'),
              ],
            ),
          ),
          Positioned(
            right: 28,
            top: 270,
            child: _GlassCard(
              padding: const EdgeInsets.fromLTRB(14, 13, 14, 13),
              borderRadius: 22,
              child: SizedBox(
                width: 112,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    Row(
                      children: <Widget>[
                        Container(
                          width: 28,
                          height: 28,
                          decoration: BoxDecoration(
                            color: _mint.withValues(alpha: 0.26),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(
                            Icons.bookmark_added_rounded,
                            size: 16,
                            color: _deepTeal,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Saved',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AppTypography.product(
                              fontSize: 11.4,
                              fontWeight: FontWeight.w800,
                              color: _ink,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Text(
                      '12 matches',
                      style: AppTypography.product(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        color: _primary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Ready to apply',
                      style: AppTypography.product(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF6D7891),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            left: 56,
            right: 36,
            bottom: 58,
            child: Container(
              padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(24),
                gradient: const LinearGradient(
                  colors: <Color>[Color(0xFF2A13E6), Color(0xFF4B35FF)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                boxShadow: <BoxShadow>[
                  BoxShadow(
                    color: _primary.withValues(alpha: 0.18),
                    blurRadius: 20,
                    offset: const Offset(0, 12),
                  ),
                ],
              ),
              child: Row(
                children: <Widget>[
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.16),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.auto_awesome_rounded,
                      size: 18,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: <Widget>[
                        Text(
                          'UX Research Internship',
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: AppTypography.product(
                            fontSize: 15.2,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                            height: 1.15,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'TechNova Global Inc.',
                          style: AppTypography.product(
                            fontSize: 11.8,
                            fontWeight: FontWeight.w600,
                            color: Colors.white.withValues(alpha: 0.72),
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
    );
  }

  Widget _buildFutureHero() {
    return SizedBox(
      height: spec.heroHeight,
      child: Stack(
        children: <Widget>[
          Positioned.fill(
            child: Stack(
              fit: StackFit.expand,
              children: <Widget>[
                Image.asset(
                  spec.assetPath,
                  fit: BoxFit.cover,
                  alignment: Alignment.center,
                  filterQuality: FilterQuality.high,
                ),
                const DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: <Color>[
                        Color(0x20F7F8FE),
                        Color(0x0007112E),
                        Color(0xC60A1026),
                      ],
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Positioned(
            left: 16,
            top: 72,
            child: Opacity(
              opacity: 0.8,
              child: _GlassCard(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 14,
                ),
                borderRadius: 28,
                child: SizedBox(
                  width: 204,
                  child: Row(
                    children: <Widget>[
                      Container(
                        width: 46,
                        height: 46,
                        decoration: const BoxDecoration(
                          color: _primary,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.work_rounded,
                          color: Colors.white,
                          size: 22,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: <Widget>[
                            Text(
                              'INTERNSHIP',
                              style: AppTypography.product(
                                fontSize: 11,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 0.9,
                                color: _primary,
                              ),
                            ),
                            const SizedBox(height: 3),
                            Text(
                              'UX Design at Tech',
                              style: AppTypography.product(
                                fontSize: 14.5,
                                fontWeight: FontWeight.w800,
                                color: _ink,
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
          ),
          Positioned(
            right: 12,
            top: 182,
            child: Opacity(
              opacity: 0.8,
              child: _GlassCard(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 14,
                ),
                borderRadius: 28,
                child: SizedBox(
                  width: 194,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      Row(
                        children: <Widget>[
                          const Icon(
                            Icons.workspace_premium_outlined,
                            color: _deepTeal,
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Global Scholarship',
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: AppTypography.product(
                                fontSize: 15,
                                fontWeight: FontWeight.w800,
                                color: _ink,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Full Tuition Coverage',
                        style: AppTypography.product(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF6D7891),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          Positioned(
            left: 12,
            bottom: 28,
            child: _GlassCard(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              borderRadius: 28,
              child: SizedBox(
                width: 188,
                child: Row(
                  children: <Widget>[
                    SizedBox(
                      width: 50,
                      height: 50,
                      child: Stack(
                        alignment: Alignment.center,
                        children: <Widget>[
                          SizedBox(
                            width: 50,
                            height: 50,
                            child: CircularProgressIndicator(
                              value: 0.7,
                              strokeWidth: 4,
                              backgroundColor: const Color(0xFFDDE4EF),
                              valueColor: const AlwaysStoppedAnimation<Color>(
                                _deepTeal,
                              ),
                            ),
                          ),
                          const Icon(
                            Icons.insights_outlined,
                            color: _deepTeal,
                            size: 18,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Text(
                            'Data Science Pro',
                            style: AppTypography.product(
                              fontSize: 14,
                              fontWeight: FontWeight.w800,
                              color: _ink,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '70% Completed',
                            style: AppTypography.product(
                              fontSize: 12.5,
                              fontWeight: FontWeight.w600,
                              color: _deepTeal,
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
      ),
    );
  }
}

class _BottomSheetStage extends StatelessWidget {
  final _SlideSpec spec;
  final int index;
  final int totalSlides;
  final bool isLastSlide;
  final bool isSignedIn;
  final Future<void> Function() onPrimaryAction;
  final Future<void> Function() onForward;
  final Future<void> Function() onBack;
  final Future<void> Function() onLogin;

  const _BottomSheetStage({
    required this.spec,
    required this.index,
    required this.totalSlides,
    required this.isLastSlide,
    required this.isSignedIn,
    required this.onPrimaryAction,
    required this.onForward,
    required this.onBack,
    required this.onLogin,
  });

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);

    return LayoutBuilder(
      builder: (context, constraints) {
        final contentScale = math.min(
          constraints.maxHeight / spec.sheetHeight,
          1.0,
        );

        double scaled(double value, {double? min}) {
          final scaledValue = value * contentScale;
          if (min == null) {
            return scaledValue;
          }
          return math.max(min, scaledValue);
        }

        final primaryLabel = index == 0
            ? 'Get Started'
            : isLastSlide
            ? (isSignedIn ? 'Continue' : 'Create account')
            : 'Next';
        final primaryKey = index == 0
            ? const ValueKey<String>('onboarding_primary_button')
            : isLastSlide
            ? const ValueKey<String>('onboarding_final_primary_button')
            : null;
        final helperTitle = isLastSlide && !isSignedIn
            ? 'Returning to FutureGate?'
            : null;
        final helperSpacing = isLastSlide
            ? scaled(10, min: 6)
            : scaled(12, min: 8);
        final navigationLayout = index == 0
            ? _NavigationLayout.primaryOnly
            : isLastSlide
            ? _NavigationLayout.backAndPrimary
            : _NavigationLayout.arrowsOnly;
        final titleFontSize = isLastSlide
            ? scaled(25.2, min: 18.2)
            : scaled(27, min: 19);
        final titleSpacing = isLastSlide
            ? scaled(14, min: 10)
            : scaled(16, min: 11);
        final descriptionFontSize = isLastSlide
            ? scaled(14.2, min: 11.7)
            : scaled(15, min: 12.1);
        final descriptionHeight = isLastSlide ? 1.5 : 1.58;

        return Container(
          height: constraints.maxHeight,
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(
            color: colors.surface,
            borderRadius: BorderRadius.vertical(
              top: Radius.circular(scaled(38, min: 28)),
            ),
            boxShadow: <BoxShadow>[
              BoxShadow(
                color: colors.shadow.withValues(
                  alpha: colors.isDarkMode ? 0.34 : 0.08,
                ),
                blurRadius: scaled(22, min: 14),
                offset: Offset(0, -scaled(6, min: 4)),
              ),
            ],
          ),
          child: Padding(
            padding: EdgeInsets.fromLTRB(
              scaled(24, min: 18),
              scaled(20, min: 14),
              scaled(24, min: 18),
              scaled(20, min: 14),
            ),
            child: Column(
              crossAxisAlignment: spec.bodyAlign,
              children: <Widget>[
                Row(
                  mainAxisAlignment: spec.indicatorAlignment,
                  children: List<Widget>.generate(totalSlides, (dotIndex) {
                    final isActive = dotIndex == index;
                    return Container(
                      margin: EdgeInsets.only(
                        right: dotIndex == totalSlides - 1
                            ? 0
                            : scaled(10, min: 6),
                      ),
                      width: isActive
                          ? scaled(48, min: 34)
                          : scaled(22, min: 16),
                      height: scaled(10, min: 7),
                      decoration: BoxDecoration(
                        color: isActive ? colors.primary : colors.border,
                        borderRadius: BorderRadius.circular(999),
                      ),
                    );
                  }),
                ),
                SizedBox(height: scaled(20, min: 14)),
                RichText(
                  key: ValueKey<String>('onboarding_title_$index'),
                  textAlign: spec.titleAlign,
                  text: TextSpan(
                    children: spec.titleParts
                        .map(
                          (part) => TextSpan(
                            text: part.text,
                            style: AppTypography.product(
                              fontSize: titleFontSize,
                              height: 1.18,
                              fontWeight: FontWeight.w700,
                              color: part.highlight
                                  ? colors.primary
                                  : colors.textPrimary,
                            ),
                          ),
                        )
                        .toList(growable: false),
                  ),
                ),
                SizedBox(height: titleSpacing),
                Text(
                  spec.description,
                  textAlign: spec.titleAlign,
                  style: AppTypography.product(
                    fontSize: descriptionFontSize,
                    height: descriptionHeight,
                    fontWeight: FontWeight.w600,
                    color: colors.textSecondary,
                  ),
                ),
                const Spacer(),
                if (helperTitle != null)
                  Padding(
                    padding: EdgeInsets.only(bottom: helperSpacing),
                    child: Wrap(
                      alignment: WrapAlignment.center,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      spacing: scaled(4, min: 3),
                      runSpacing: scaled(4, min: 3),
                      children: <Widget>[
                        Text(
                          helperTitle,
                          textAlign: TextAlign.center,
                          style: AppTypography.product(
                            fontSize: scaled(12.4, min: 10.4),
                            fontWeight: FontWeight.w800,
                            color: colors.primary.withValues(alpha: 0.84),
                          ),
                        ),
                        TextButton(
                          key: const ValueKey<String>('onboarding_login_link'),
                          onPressed: onLogin,
                          style: TextButton.styleFrom(
                            foregroundColor: colors.primary,
                            padding: EdgeInsets.symmetric(
                              horizontal: scaled(6, min: 4),
                              vertical: 0,
                            ),
                            minimumSize: Size.zero,
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ),
                          child: Text(
                            'Sign in',
                            style: AppTypography.product(
                              fontSize: scaled(12.8, min: 10.6),
                              fontWeight: FontWeight.w800,
                              color: colors.primary,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                _NavigationPanel(
                  layout: navigationLayout,
                  scale: contentScale,
                  primaryLabel: primaryLabel,
                  primaryKey: primaryKey,
                  onPrimary: index == 0 ? onPrimaryAction : onForward,
                  backKey: const ValueKey<String>('onboarding_back_button'),
                  forwardKey: const ValueKey<String>(
                    'onboarding_forward_button',
                  ),
                  onBack: onBack,
                  onForward: onForward,
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _NavigationPanel extends StatelessWidget {
  final _NavigationLayout layout;
  final double scale;
  final String primaryLabel;
  final Key? primaryKey;
  final Key backKey;
  final Key forwardKey;
  final Future<void> Function() onPrimary;
  final Future<void> Function() onBack;
  final Future<void> Function() onForward;

  const _NavigationPanel({
    required this.layout,
    required this.scale,
    required this.primaryLabel,
    required this.primaryKey,
    required this.backKey,
    required this.forwardKey,
    required this.onPrimary,
    required this.onBack,
    required this.onForward,
  });

  @override
  Widget build(BuildContext context) {
    double scaled(double value, {double? min}) {
      final scaledValue = value * scale;
      if (min == null) {
        return scaledValue;
      }
      return math.max(min, scaledValue);
    }

    final actionSize = scaled(56, min: 44);
    final gap = scaled(10, min: 8);

    switch (layout) {
      case _NavigationLayout.primaryOnly:
        return Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: scaled(260, min: 220)),
            child: _PrimaryPillButton(
              key: primaryKey,
              label: primaryLabel,
              scale: scale,
              onPressed: onPrimary,
            ),
          ),
        );
      case _NavigationLayout.arrowsOnly:
        return Padding(
          padding: EdgeInsets.symmetric(horizontal: scaled(6, min: 2)),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: <Widget>[
              _CircularActionButton(
                key: backKey,
                icon: Icons.arrow_back_rounded,
                size: actionSize,
                onPressed: onBack,
                filled: false,
              ),
              _CircularActionButton(
                key: forwardKey,
                icon: Icons.arrow_forward_rounded,
                size: actionSize,
                onPressed: onForward,
                filled: true,
              ),
            ],
          ),
        );
      case _NavigationLayout.backAndPrimary:
        return Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: <Widget>[
            _CircularActionButton(
              key: backKey,
              icon: Icons.arrow_back_rounded,
              size: actionSize,
              onPressed: onBack,
              filled: false,
            ),
            SizedBox(width: gap),
            Expanded(
              child: _PrimaryPillButton(
                key: primaryKey,
                label: primaryLabel,
                scale: scale,
                onPressed: onPrimary,
              ),
            ),
          ],
        );
    }
  }
}

enum _NavigationLayout { primaryOnly, arrowsOnly, backAndPrimary }

class _CircularActionButton extends StatelessWidget {
  final IconData icon;
  final double size;
  final bool filled;
  final Future<void> Function() onPressed;

  const _CircularActionButton({
    super.key,
    required this.icon,
    required this.size,
    required this.filled,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    final background = filled
        ? LinearGradient(
            colors: <Color>[colors.primary, colors.primaryDeep],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          )
        : null;

    return Semantics(
      button: true,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(999),
          child: Ink(
            width: size,
            height: size,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: filled ? null : colors.surfaceMuted,
              gradient: background,
              border: filled
                  ? null
                  : Border.all(color: colors.border, width: 1.1),
            ),
            child: Icon(
              icon,
              color: filled ? Colors.white : colors.textMuted,
              size: size * 0.42,
            ),
          ),
        ),
      ),
    );
  }
}

class _PrimaryPillButton extends StatelessWidget {
  final String label;
  final double scale;
  final Future<void> Function() onPressed;

  const _PrimaryPillButton({
    super.key,
    required this.label,
    required this.scale,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);

    double scaled(double value, {double? min}) {
      final scaledValue = value * scale;
      if (min == null) {
        return scaledValue;
      }
      return math.max(min, scaledValue);
    }

    return SizedBox(
      height: scaled(56, min: 44),
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(scaled(28, min: 22)),
          gradient: LinearGradient(
            colors: <Color>[colors.primaryDeep, colors.primary],
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
          ),
          boxShadow: <BoxShadow>[
            BoxShadow(
              color: colors.primary.withValues(alpha: 0.22),
              blurRadius: scaled(16, min: 10),
              offset: Offset(0, scaled(8, min: 5)),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onPressed,
            borderRadius: BorderRadius.circular(scaled(28, min: 22)),
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: scaled(18, min: 12)),
              child: Center(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    label,
                    maxLines: 1,
                    style: AppTypography.product(
                      fontSize: scaled(15.5, min: 13.2),
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _SkillChip extends StatelessWidget {
  static const Color _primary = Color(0xFF3424F5);
  static const Color _ink = Color(0xFF2D344C);
  static const Color _deepTeal = Color(0xFF05756B);

  final String label;
  final bool primary;
  final bool filled;

  const _SkillChip({
    required this.label,
    this.primary = false,
    this.filled = false,
  });

  @override
  Widget build(BuildContext context) {
    final backgroundColor = filled
        ? _deepTeal
        : Colors.white.withValues(alpha: 0.92);
    final textColor = filled
        ? Colors.white
        : primary
        ? _primary
        : _ink;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 11),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(999),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: const Color(0xFF23304D).withValues(alpha: 0.06),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Text(
        label,
        style: AppTypography.product(
          fontSize: 12.8,
          fontWeight: FontWeight.w800,
          color: textColor,
        ),
      ),
    );
  }
}

class _GlowBlob extends StatelessWidget {
  final double size;
  final Color color;

  const _GlowBlob({required this.size, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
    );
  }
}

class _GlassCard extends StatelessWidget {
  final EdgeInsetsGeometry padding;
  final double borderRadius;
  final Widget child;

  const _GlassCard({
    required this.padding,
    required this.borderRadius,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 7, sigmaY: 7),
        child: Container(
          padding: padding,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.88),
            borderRadius: BorderRadius.circular(borderRadius),
            boxShadow: <BoxShadow>[
              BoxShadow(
                color: const Color(0xFF1B2641).withValues(alpha: 0.08),
                blurRadius: 18,
                offset: const Offset(0, 9),
              ),
            ],
          ),
          child: child,
        ),
      ),
    );
  }
}

class _SlideSpec {
  final _HeroLayout layout;
  final String assetPath;
  final double heroHeight;
  final double sheetHeight;
  final double sheetOffset;
  final MainAxisAlignment indicatorAlignment;
  final List<_TitlePart> titleParts;
  final String description;
  final TextAlign titleAlign;
  final CrossAxisAlignment bodyAlign;

  const _SlideSpec({
    required this.layout,
    required this.assetPath,
    required this.heroHeight,
    required this.sheetHeight,
    required this.sheetOffset,
    required this.indicatorAlignment,
    required this.titleParts,
    required this.description,
    required this.titleAlign,
    required this.bodyAlign,
  });
}

class _TitlePart {
  final String text;
  final bool highlight;

  const _TitlePart({required this.text, this.highlight = false});
}

enum _HeroLayout { connect, profile, future }
