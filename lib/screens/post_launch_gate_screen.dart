import 'package:flutter/material.dart';

import '../services/app_intro_preferences_service.dart';
import '../theme/app_colors.dart';
import '../widgets/shared/app_loading.dart';
import 'auth_wrapper.dart';
import 'onboarding/get_started_screen.dart';

class PostLaunchGateScreen extends StatefulWidget {
  final AppIntroPreferencesService? introPreferencesService;

  const PostLaunchGateScreen({super.key, this.introPreferencesService});

  @override
  State<PostLaunchGateScreen> createState() => _PostLaunchGateScreenState();
}

class _PostLaunchGateScreenState extends State<PostLaunchGateScreen> {
  late final AppIntroPreferencesService _introPreferencesService;
  late final Future<bool> _hasSeenGetStartedFuture;

  @override
  void initState() {
    super.initState();
    _introPreferencesService =
        widget.introPreferencesService ?? AppIntroPreferencesService();
    _hasSeenGetStartedFuture = _introPreferencesService.hasSeenGetStarted();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<bool>(
      future: _hasSeenGetStartedFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const _PostLaunchLoadingScreen();
        }

        final hasSeenGetStarted = snapshot.data ?? false;
        if (hasSeenGetStarted) {
          return const AuthWrapper();
        }

        return GetStartedScreen(
          introPreferencesService: _introPreferencesService,
        );
      },
    );
  }
}

class _PostLaunchLoadingScreen extends StatelessWidget {
  const _PostLaunchLoadingScreen();

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: DecoratedBox(
        decoration: BoxDecoration(gradient: colors.shellGradient),
        child: const SafeArea(child: AppLoadingView(showBottomBar: true)),
      ),
    );
  }
}
