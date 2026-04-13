import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:video_player/video_player.dart';

import '../widgets/shared/app_logo.dart';
import 'auth_wrapper.dart';

/// Full-screen launch animation screen.
///
/// Plays the branding animation video immersively, then transitions
/// smoothly into the [AuthWrapper]. Falls back to a static branded
/// screen if video initialisation fails.
class LaunchScreen extends StatefulWidget {
  const LaunchScreen({super.key});

  @override
  State<LaunchScreen> createState() => _LaunchScreenState();
}

class _LaunchScreenState extends State<LaunchScreen>
    with SingleTickerProviderStateMixin {
  late final VideoPlayerController _controller;
  late final AnimationController _fadeController;
  bool _hasNavigated = false;
  bool _videoReady = false;

  @override
  void initState() {
    super.initState();

    // Immersive full-screen while the animation plays.
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);

    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );

    _controller = VideoPlayerController.asset(AppBrandAssets.animation)
      ..initialize().then((_) {
        if (!mounted) return;
        setState(() => _videoReady = true);
        _controller.play();
      }).catchError((_) {
        // If video fails, just skip to the app after a brief delay.
        _navigateToApp();
      });

    _controller.addListener(_onVideoUpdate);
  }

  void _onVideoUpdate() {
    if (_hasNavigated) return;
    final value = _controller.value;
    if (!value.isInitialized) return;

    // Navigate when video finishes.
    if (value.position >= value.duration && value.duration > Duration.zero) {
      _navigateToApp();
    }
  }

  Future<void> _navigateToApp() async {
    if (_hasNavigated) return;
    _hasNavigated = true;

    // Restore system UI.
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);

    // Fade out, then navigate.
    await _fadeController.forward();

    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        pageBuilder: (_, _, _) => const AuthWrapper(),
        transitionDuration: const Duration(milliseconds: 350),
        transitionsBuilder: (_, animation, _, child) {
          return FadeTransition(opacity: animation, child: child);
        },
      ),
    );
  }

  @override
  void dispose() {
    _controller.removeListener(_onVideoUpdate);
    _controller.dispose();
    _fadeController.dispose();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: FadeTransition(
        opacity: ReverseAnimation(_fadeController),
        child: _videoReady
            ? SizedBox.expand(
                child: FittedBox(
                  fit: BoxFit.cover,
                  child: SizedBox(
                    width: _controller.value.size.width,
                    height: _controller.value.size.height,
                    child: VideoPlayer(_controller),
                  ),
                ),
              )
            : const Center(
                child: AppLogoMark(size: 120, padding: 16),
              ),
      ),
    );
  }
}
