import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:video_player/video_player.dart';

import '../providers/auth_provider.dart';
import '../theme/app_colors.dart';
import '../widgets/shared/app_logo.dart';
import 'post_launch_gate_screen.dart';

/// Full-screen immersive launch animation.
///
/// • Hides system UI and plays the branding video cover-scaled to the full screen.
/// • Starts loading auth state in parallel so there is zero loading spinner
///   after the animation ends.
/// • Falls back to an empty white screen (no logo) while the video asset loads
///   (typically < 100 ms for local assets).
class LaunchScreen extends StatefulWidget {
  const LaunchScreen({super.key});

  @override
  State<LaunchScreen> createState() => _LaunchScreenState();
}

class _LaunchScreenState extends State<LaunchScreen>
    with SingleTickerProviderStateMixin {
  late final VideoPlayerController _videoController;
  late final AnimationController _fadeController;
  bool _hasNavigated = false;
  bool _videoReady = false;

  @override
  void initState() {
    super.initState();

    // Immersive full-screen: hide status bar + nav bar while animation plays.
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);

    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 350),
    );

    // Start preloading auth state in parallel with the animation so that by
    // the time we navigate there is no loading spinner waiting for the user.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<AuthProvider>().loadCurrentUser();
    });

    _initVideo();
  }

  void _initVideo() {
    _videoController = VideoPlayerController.asset(AppBrandAssets.animation)
      ..initialize()
          .then((_) {
            if (!mounted) return;
            setState(() => _videoReady = true);
            _videoController.play();
          })
          .catchError((_) {
            // Video failed — navigate after a short fallback delay.
            Future.delayed(const Duration(seconds: 1), _navigateToApp);
          });

    _videoController.addListener(_onVideoProgress);
  }

  void _onVideoProgress() {
    if (_hasNavigated) return;
    final v = _videoController.value;
    if (!v.isInitialized || v.duration == Duration.zero) return;

    if (v.position >= v.duration) {
      _navigateToApp();
    }
  }

  Future<void> _navigateToApp() async {
    if (_hasNavigated) return;
    _hasNavigated = true;

    // Wait for auth to finish (max 3 s). Auth was started in initState so
    // it should almost always be done before the animation ends.
    final authProvider = context.read<AuthProvider>();
    for (int i = 0; i < 30 && !authProvider.isInitialLoadDone; i++) {
      await Future.delayed(const Duration(milliseconds: 100));
      if (!mounted) return;
    }

    // Restore system UI before entering the app.
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);

    // Fade the launch screen out.
    if (mounted) await _fadeController.forward();
    if (!mounted) return;

    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        pageBuilder: (_, _, _) => const PostLaunchGateScreen(),
        transitionDuration: const Duration(milliseconds: 300),
        transitionsBuilder: (_, animation, _, child) =>
            FadeTransition(opacity: animation, child: child),
      ),
    );
  }

  @override
  void dispose() {
    _videoController.removeListener(_onVideoProgress);
    _videoController.dispose();
    _fadeController.dispose();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Use the brand launch color during the brief gap before the video starts.
      backgroundColor: AppColors.of(context).splashBackground,
      body: FadeTransition(
        opacity: ReverseAnimation(_fadeController),
        child: _buildContent(),
      ),
    );
  }

  Widget _buildContent() {
    // No static logo: while the video asset is loading, show nothing.
    // Local assets initialize in < 100 ms so users never see the gap.
    if (!_videoReady || !_videoController.value.isInitialized) {
      return const SizedBox.expand();
    }

    final vSize = _videoController.value.size;
    final hasSize = vSize.width > 0 && vSize.height > 0;

    return Stack(
      fit: StackFit.expand,
      children: [
        if (hasSize)
          // FittedBox with cover scales the video up/down so it fills the
          // entire screen with no black bars, cropping symmetrically if needed.
          FittedBox(
            fit: BoxFit.cover,
            child: SizedBox(
              width: vSize.width,
              height: vSize.height,
              child: VideoPlayer(_videoController),
            ),
          )
        else
          // Fallback when the platform hasn't reported the size yet: let the
          // VideoPlayer widget fill the stack through StackFit.expand.
          VideoPlayer(_videoController),
      ],
    );
  }
}
