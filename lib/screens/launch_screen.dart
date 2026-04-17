import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:video_player/video_player.dart';

import '../l10n/generated/app_localizations.dart';
import '../providers/auth_provider.dart';
import '../services/app_intro_preferences_service.dart';
import '../theme/app_colors.dart';
import '../widgets/shared/app_logo.dart';
import 'post_launch_gate_screen.dart';

/// Full-screen immersive launch animation.
///
/// Hides system UI and plays the branding video cover-scaled to the full
/// screen. The animation can be skipped from Settings for faster launches.
class LaunchScreen extends StatefulWidget {
  final AppIntroPreferencesService? introPreferencesService;

  const LaunchScreen({super.key, this.introPreferencesService});

  @override
  State<LaunchScreen> createState() => _LaunchScreenState();
}

class _LaunchScreenState extends State<LaunchScreen>
    with SingleTickerProviderStateMixin {
  late final AppIntroPreferencesService _introPreferencesService;
  late final AnimationController _fadeController;
  VideoPlayerController? _videoController;
  bool _hasNavigated = false;
  bool _videoReady = false;

  @override
  void initState() {
    super.initState();
    _introPreferencesService =
        widget.introPreferencesService ?? AppIntroPreferencesService();

    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 350),
    );

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<AuthProvider>().loadCurrentUser();
    });

    _startLaunchFlow();
  }

  Future<void> _startLaunchFlow() async {
    final skipAnimation = await _introPreferencesService
        .shouldSkipLaunchAnimation();
    if (!mounted) return;

    if (skipAnimation) {
      await _navigateToApp(skipFade: true, waitForAuth: false);
      return;
    }

    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    _initVideo();
  }

  void _initVideo() {
    final controller = VideoPlayerController.asset(AppBrandAssets.animation);
    _videoController = controller;

    controller
        .initialize()
        .then((_) {
          if (!mounted) return;
          setState(() => _videoReady = true);
          controller.play();
        })
        .catchError((_) {
          Future.delayed(const Duration(seconds: 1), () => _navigateToApp());
        });

    controller.addListener(_onVideoProgress);
  }

  void _onVideoProgress() {
    if (_hasNavigated) return;
    final controller = _videoController;
    if (controller == null) return;

    final value = controller.value;
    if (!value.isInitialized || value.duration == Duration.zero) return;

    if (value.position >= value.duration) {
      _navigateToApp();
    }
  }

  Future<void> _navigateToApp({
    bool skipFade = false,
    bool waitForAuth = true,
  }) async {
    if (!mounted || _hasNavigated) return;
    _hasNavigated = true;

    if (waitForAuth) {
      final authProvider = context.read<AuthProvider>();
      for (int i = 0; i < 30 && !authProvider.isInitialLoadDone; i++) {
        await Future.delayed(const Duration(milliseconds: 100));
        if (!mounted) return;
      }
    }

    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);

    if (!skipFade) {
      await _fadeController.forward();
    }
    if (!mounted) return;

    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        pageBuilder: (_, _, _) => const PostLaunchGateScreen(),
        transitionDuration: skipFade
            ? Duration.zero
            : const Duration(milliseconds: 300),
        transitionsBuilder: (_, animation, _, child) =>
            FadeTransition(opacity: animation, child: child),
      ),
    );
  }

  @override
  void dispose() {
    final controller = _videoController;
    if (controller != null) {
      controller.removeListener(_onVideoProgress);
      controller.dispose();
    }
    _fadeController.dispose();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.of(context).splashBackground,
      body: FadeTransition(
        opacity: ReverseAnimation(_fadeController),
        child: _buildContent(),
      ),
    );
  }

  Widget _buildContent() {
    final controller = _videoController;
    if (!_videoReady || controller == null || !controller.value.isInitialized) {
      return const SizedBox.expand();
    }

    final videoSize = controller.value.size;
    final hasSize = videoSize.width > 0 && videoSize.height > 0;

    return Stack(
      fit: StackFit.expand,
      children: [
        if (hasSize)
          FittedBox(
            fit: BoxFit.cover,
            child: SizedBox(
              width: videoSize.width,
              height: videoSize.height,
              child: VideoPlayer(controller),
            ),
          )
        else
          VideoPlayer(controller),
        const SafeArea(
          minimum: EdgeInsets.fromLTRB(18, 0, 18, 22),
          child: Align(
            alignment: Alignment.bottomCenter,
            child: _LaunchAnimationHint(),
          ),
        ),
      ],
    );
  }
}

class _LaunchAnimationHint extends StatelessWidget {
  const _LaunchAnimationHint();

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 360),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.38),
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: Colors.white.withValues(alpha: 0.18)),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.info_outline_rounded,
                color: Colors.white.withValues(alpha: 0.9),
                size: 16,
              ),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  AppLocalizations.of(context)!.launchAnimationHint,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.92),
                    fontSize: 11.5,
                    fontWeight: FontWeight.w600,
                    height: 1.25,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
