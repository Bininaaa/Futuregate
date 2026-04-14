import 'package:flutter/material.dart';

import '../services/app_intro_preferences_service.dart';
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
    return const Scaffold(
      backgroundColor: Color(0xFFF4F7FB),
      body: Center(child: CircularProgressIndicator()),
    );
  }
}
