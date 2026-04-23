import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../l10n/generated/app_localizations.dart';
import 'app_feedback.dart';

class AppDoubleBackExitScope extends StatefulWidget {
  final Widget child;
  final Duration interval;

  const AppDoubleBackExitScope({
    super.key,
    required this.child,
    this.interval = const Duration(seconds: 2),
  });

  @override
  State<AppDoubleBackExitScope> createState() => _AppDoubleBackExitScopeState();
}

class _AppDoubleBackExitScopeState extends State<AppDoubleBackExitScope> {
  DateTime? _lastBackPressedAt;

  bool get _isEnabled {
    if (kIsWeb) {
      return false;
    }

    return switch (defaultTargetPlatform) {
      TargetPlatform.android || TargetPlatform.fuchsia => true,
      _ => false,
    };
  }

  void _handleBackPressed() {
    final focusedNode = FocusManager.instance.primaryFocus;
    if (focusedNode?.hasFocus ?? false) {
      focusedNode?.unfocus();
      return;
    }

    final now = DateTime.now();
    final lastBackPressedAt = _lastBackPressedAt;
    if (lastBackPressedAt == null ||
        now.difference(lastBackPressedAt) > widget.interval) {
      _lastBackPressedAt = now;

      final l10n = AppLocalizations.of(context)!;
      context.showAppSnackBar(
        l10n.pressBackAgainToExitApp,
        icon: Icons.exit_to_app_rounded,
        duration: widget.interval,
      );
      return;
    }

    SystemNavigator.pop();
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: !_isEnabled,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop || !_isEnabled) {
          return;
        }

        _handleBackPressed();
      },
      child: widget.child,
    );
  }
}
