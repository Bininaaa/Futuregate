import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../l10n/generated/app_localizations.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_typography.dart';

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

  Future<void> _handleBackPressed() async {
    final keyboardVisible = MediaQuery.viewInsetsOf(context).bottom > 0;
    if (keyboardVisible) {
      FocusManager.instance.primaryFocus?.unfocus();
      return;
    }

    final now = DateTime.now();
    final lastBackPressedAt = _lastBackPressedAt;
    if (lastBackPressedAt == null ||
        now.difference(lastBackPressedAt) > widget.interval) {
      _lastBackPressedAt = now;

      HapticFeedback.selectionClick();
      _showExitPrompt();
      return;
    }

    await SystemNavigator.pop();
  }

  void _showExitPrompt() {
    final messenger = ScaffoldMessenger.maybeOf(context);
    if (messenger == null) {
      return;
    }

    final l10n = AppLocalizations.of(context)!;
    messenger.hideCurrentSnackBar();
    messenger.showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        elevation: 0,
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 18),
        padding: EdgeInsets.zero,
        duration: widget.interval,
        dismissDirection: DismissDirection.none,
        backgroundColor: Colors.transparent,
        content: _ExitPromptCard(
          message: l10n.pressBackAgainToExitApp,
          duration: widget.interval,
        ),
      ),
    );
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

class _ExitPromptCard extends StatelessWidget {
  final String message;
  final Duration duration;

  const _ExitPromptCard({required this.message, required this.duration});

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    final isDark = colors.isDarkMode;
    final primaryTint = isDark ? colors.primary : colors.primaryDeep;
    final secondaryTint = isDark ? colors.secondary : colors.secondaryDeep;
    final borderColor = isDark
        ? colors.borderStrong.withValues(alpha: 0.82)
        : colors.border.withValues(alpha: 0.90);
    final surfaceGradient = LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: <Color>[
        Color.alphaBlend(
          colors.primary.withValues(alpha: isDark ? 0.14 : 0.05),
          colors.surfaceElevated.withValues(alpha: isDark ? 0.94 : 0.98),
        ),
        Color.alphaBlend(
          colors.secondary.withValues(alpha: isDark ? 0.12 : 0.05),
          colors.backgroundAlt.withValues(alpha: isDark ? 0.92 : 0.97),
        ),
      ],
    );

    return Stack(
      children: <Widget>[
        ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: surfaceGradient,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: borderColor),
                boxShadow: <BoxShadow>[
                  BoxShadow(
                    color: colors.shadow.withValues(
                      alpha: isDark ? 0.30 : 0.09,
                    ),
                    blurRadius: 28,
                    offset: const Offset(0, 16),
                  ),
                  BoxShadow(
                    color: colors.secondary.withValues(
                      alpha: isDark ? 0.16 : 0.08,
                    ),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(14, 13, 14, 16),
                child: Row(
                  children: <Widget>[
                    Container(
                      width: 46,
                      height: 46,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: <Color>[
                            colors.primaryDeep,
                            colors.primary,
                            colors.secondary,
                          ],
                        ),
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: <BoxShadow>[
                          BoxShadow(
                            color: colors.primary.withValues(alpha: 0.18),
                            blurRadius: 16,
                            offset: const Offset(0, 8),
                          ),
                          BoxShadow(
                            color: colors.secondary.withValues(alpha: 0.12),
                            blurRadius: 16,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.exit_to_app_rounded,
                        color: Colors.white,
                        size: 22,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        message,
                        style: AppTypography.product(
                          fontSize: 13.1,
                          fontWeight: FontWeight.w700,
                          height: 1.35,
                          color: colors.textPrimary,
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: Color.alphaBlend(
                          colors.secondary.withValues(
                            alpha: isDark ? 0.18 : 0.08,
                          ),
                          colors.surface.withValues(
                            alpha: isDark ? 0.80 : 0.92,
                          ),
                        ),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: colors.secondary.withValues(
                            alpha: isDark ? 0.22 : 0.12,
                          ),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: <Widget>[
                          Icon(
                            Icons.keyboard_return_rounded,
                            size: 14,
                            color: secondaryTint,
                          ),
                          const SizedBox(width: 5),
                          Text(
                            '2x',
                            style: AppTypography.display(
                              fontSize: 11.4,
                              fontWeight: FontWeight.w700,
                              color: secondaryTint,
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
          left: 12,
          right: 12,
          bottom: 8,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: TweenAnimationBuilder<double>(
              tween: Tween<double>(begin: 1, end: 0),
              duration: duration,
              builder: (context, value, child) {
                return Stack(
                  children: <Widget>[
                    Container(
                      height: 4,
                      color: colors.borderStrong.withValues(
                        alpha: isDark ? 0.30 : 0.42,
                      ),
                    ),
                    FractionallySizedBox(
                      widthFactor: value,
                      alignment: Alignment.centerLeft,
                      child: Container(
                        height: 4,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: <Color>[primaryTint, colors.secondary],
                          ),
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ),
      ],
    );
  }
}
