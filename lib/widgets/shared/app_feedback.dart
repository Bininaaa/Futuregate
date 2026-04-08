import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

enum AppFeedbackType { error, warning, success, info, neutral }

@immutable
class AppFeedbackTheme extends ThemeExtension<AppFeedbackTheme> {
  final Color info;
  final Color success;
  final Color warning;
  final Color error;
  final Color neutral;

  const AppFeedbackTheme({
    required this.info,
    required this.success,
    required this.warning,
    required this.error,
    required this.neutral,
  });

  factory AppFeedbackTheme.fallback(ColorScheme colorScheme) {
    return AppFeedbackTheme(
      info: colorScheme.primary,
      success: const Color(0xFF179D6C),
      warning: const Color(0xFFD97706),
      error: colorScheme.error,
      neutral: const Color(0xFF475569),
    );
  }

  static AppFeedbackTheme of(BuildContext context) {
    final theme = Theme.of(context);
    return theme.extension<AppFeedbackTheme>() ??
        AppFeedbackTheme.fallback(theme.colorScheme);
  }

  AppFeedbackVariant resolve(
    BuildContext context,
    AppFeedbackType type, {
    Color? accentColor,
  }) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final surface = scheme.surface;
    final onSurface = scheme.onSurface;
    final base =
        accentColor ??
        switch (type) {
          AppFeedbackType.error => error,
          AppFeedbackType.warning => warning,
          AppFeedbackType.success => success,
          AppFeedbackType.info => info,
          AppFeedbackType.neutral => neutral,
        };

    return AppFeedbackVariant(
      accent: base,
      background: _blend(base, surface, 0.08),
      surfaceHighlight: _blend(base, surface, 0.03),
      border: _blend(base, surface, 0.18),
      shadow: base.withValues(alpha: 0.10),
      iconBackground: _blend(base, surface, 0.13),
      titleColor: onSurface,
      messageColor: onSurface.withValues(alpha: 0.74),
      actionColor: base,
      icon: switch (type) {
        AppFeedbackType.error => Icons.error_outline_rounded,
        AppFeedbackType.warning => Icons.warning_amber_rounded,
        AppFeedbackType.success => Icons.check_circle_outline_rounded,
        AppFeedbackType.info => Icons.info_outline_rounded,
        AppFeedbackType.neutral => Icons.chat_bubble_outline_rounded,
      },
    );
  }

  Color _blend(Color foreground, Color background, double opacity) {
    return Color.alphaBlend(foreground.withValues(alpha: opacity), background);
  }

  @override
  AppFeedbackTheme copyWith({
    Color? info,
    Color? success,
    Color? warning,
    Color? error,
    Color? neutral,
  }) {
    return AppFeedbackTheme(
      info: info ?? this.info,
      success: success ?? this.success,
      warning: warning ?? this.warning,
      error: error ?? this.error,
      neutral: neutral ?? this.neutral,
    );
  }

  @override
  AppFeedbackTheme lerp(ThemeExtension<AppFeedbackTheme>? other, double t) {
    if (other is! AppFeedbackTheme) {
      return this;
    }

    return AppFeedbackTheme(
      info: Color.lerp(info, other.info, t) ?? info,
      success: Color.lerp(success, other.success, t) ?? success,
      warning: Color.lerp(warning, other.warning, t) ?? warning,
      error: Color.lerp(error, other.error, t) ?? error,
      neutral: Color.lerp(neutral, other.neutral, t) ?? neutral,
    );
  }
}

@immutable
class AppFeedbackVariant {
  final Color accent;
  final Color background;
  final Color surfaceHighlight;
  final Color border;
  final Color shadow;
  final Color iconBackground;
  final Color titleColor;
  final Color messageColor;
  final Color actionColor;
  final IconData icon;

  const AppFeedbackVariant({
    required this.accent,
    required this.background,
    required this.surfaceHighlight,
    required this.border,
    required this.shadow,
    required this.iconBackground,
    required this.titleColor,
    required this.messageColor,
    required this.actionColor,
    required this.icon,
  });
}

class AppAlert extends StatelessWidget {
  final AppFeedbackType type;
  final String? title;
  final String message;
  final IconData? icon;
  final Color? accentColor;
  final Widget? action;
  final Widget? trailing;
  final bool compact;
  final bool showIcon;
  final EdgeInsetsGeometry? padding;

  const AppAlert({
    super.key,
    required this.type,
    required this.message,
    this.title,
    this.icon,
    this.accentColor,
    this.action,
    this.trailing,
    this.compact = false,
    this.showIcon = true,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    final variant = AppFeedbackTheme.of(
      context,
    ).resolve(context, type, accentColor: accentColor);
    final effectivePadding =
        padding ??
        EdgeInsets.symmetric(
          horizontal: compact ? 14 : 16,
          vertical: compact ? 12 : 14,
        );
    final effectiveIcon = icon ?? variant.icon;
    final hasTitle = (title ?? '').trim().isNotEmpty;

    return Container(
      width: double.infinity,
      padding: effectivePadding,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: <Color>[variant.background, variant.surfaceHighlight],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(compact ? 18 : 22),
        border: Border.all(color: variant.border),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: variant.shadow,
            blurRadius: compact ? 16 : 22,
            offset: Offset(0, compact ? 8 : 10),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          if (showIcon) ...<Widget>[
            Container(
              width: compact ? 34 : 40,
              height: compact ? 34 : 40,
              decoration: BoxDecoration(
                color: variant.iconBackground,
                borderRadius: BorderRadius.circular(compact ? 12 : 14),
              ),
              child: Icon(
                effectiveIcon,
                color: variant.accent,
                size: compact ? 18 : 20,
              ),
            ),
            SizedBox(width: compact ? 10 : 12),
          ],
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                if (hasTitle)
                  Text(
                    title!,
                    style: GoogleFonts.poppins(
                      fontSize: compact ? 12.6 : 13.4,
                      fontWeight: FontWeight.w700,
                      color: variant.titleColor,
                    ),
                  ),
                if (hasTitle) const SizedBox(height: 4),
                Text(
                  message,
                  style: GoogleFonts.poppins(
                    fontSize: compact ? 12.0 : 12.6,
                    fontWeight: hasTitle ? FontWeight.w500 : FontWeight.w600,
                    height: 1.45,
                    color: hasTitle
                        ? variant.messageColor
                        : variant.titleColor.withValues(alpha: 0.92),
                  ),
                ),
                if (action != null) ...<Widget>[
                  const SizedBox(height: 10),
                  action!,
                ],
              ],
            ),
          ),
          if (trailing != null) ...<Widget>[
            const SizedBox(width: 10),
            trailing!,
          ],
        ],
      ),
    );
  }
}

class AppInlineMessage extends StatelessWidget {
  final AppFeedbackType type;
  final String? title;
  final String message;
  final IconData? icon;
  final Color? accentColor;
  final Widget? action;
  final Widget? trailing;
  final bool compact;
  final bool showIcon;
  final EdgeInsetsGeometry? padding;

  const AppInlineMessage({
    super.key,
    required this.type,
    required this.message,
    this.title,
    this.icon,
    this.accentColor,
    this.action,
    this.trailing,
    this.compact = false,
    this.showIcon = true,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    return AppAlert(
      type: type,
      title: title,
      message: message,
      icon: icon,
      accentColor: accentColor,
      action: action,
      trailing: trailing,
      compact: compact,
      showIcon: showIcon,
      padding: padding,
    );
  }
}

class AppEmptyStateNotice extends StatelessWidget {
  final AppFeedbackType type;
  final IconData icon;
  final String title;
  final String message;
  final Color? accentColor;
  final Widget? action;
  final EdgeInsetsGeometry padding;

  const AppEmptyStateNotice({
    super.key,
    required this.type,
    required this.icon,
    required this.title,
    required this.message,
    this.accentColor,
    this.action,
    this.padding = const EdgeInsets.all(22),
  });

  @override
  Widget build(BuildContext context) {
    final variant = AppFeedbackTheme.of(
      context,
    ).resolve(context, type, accentColor: accentColor);

    return Container(
      width: double.infinity,
      padding: padding,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: <Color>[variant.background, variant.surfaceHighlight],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: variant.border),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: variant.shadow,
            blurRadius: 22,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Container(
            width: 68,
            height: 68,
            decoration: BoxDecoration(
              color: variant.iconBackground,
              borderRadius: BorderRadius.circular(22),
            ),
            child: Icon(icon, size: 30, color: variant.accent),
          ),
          const SizedBox(height: 16),
          Text(
            title,
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(
              fontSize: 15.8,
              fontWeight: FontWeight.w700,
              color: variant.titleColor,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            message,
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(
              fontSize: 12.6,
              fontWeight: FontWeight.w500,
              height: 1.55,
              color: variant.messageColor,
            ),
          ),
          if (action != null) ...<Widget>[const SizedBox(height: 18), action!],
        ],
      ),
    );
  }
}

class AppFieldErrorText extends StatelessWidget {
  final String message;
  final AppFeedbackType type;
  final IconData? icon;
  final Color? accentColor;

  const AppFieldErrorText({
    super.key,
    required this.message,
    this.type = AppFeedbackType.error,
    this.icon,
    this.accentColor,
  });

  @override
  Widget build(BuildContext context) {
    final variant = AppFeedbackTheme.of(
      context,
    ).resolve(context, type, accentColor: accentColor);

    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Padding(
            padding: const EdgeInsets.only(top: 1),
            child: Icon(icon ?? variant.icon, size: 14, color: variant.accent),
          ),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              message,
              style: GoogleFonts.poppins(
                fontSize: 11.6,
                fontWeight: FontWeight.w600,
                height: 1.35,
                color: variant.accent,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class AppFeedbackButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final AppFeedbackType type;
  final IconData? icon;
  final Color? accentColor;
  final bool outlined;

  const AppFeedbackButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.type = AppFeedbackType.info,
    this.icon,
    this.accentColor,
    this.outlined = false,
  });

  @override
  Widget build(BuildContext context) {
    final variant = AppFeedbackTheme.of(
      context,
    ).resolve(context, type, accentColor: accentColor);

    if (outlined) {
      return OutlinedButton.icon(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          foregroundColor: variant.actionColor,
          side: BorderSide(color: variant.border),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        icon: icon == null ? const SizedBox.shrink() : Icon(icon, size: 16),
        label: Text(
          label,
          style: GoogleFonts.poppins(
            fontSize: 12.2,
            fontWeight: FontWeight.w700,
            color: variant.actionColor,
          ),
        ),
      );
    }

    return FilledButton.icon(
      onPressed: onPressed,
      style: FilledButton.styleFrom(
        backgroundColor: variant.actionColor,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      icon: icon == null ? const SizedBox.shrink() : Icon(icon, size: 16),
      label: Text(
        label,
        style: GoogleFonts.poppins(
          fontSize: 12.2,
          fontWeight: FontWeight.w700,
          color: Colors.white,
        ),
      ),
    );
  }
}

class AppSnackbar {
  const AppSnackbar._();

  static SnackBar build(
    BuildContext context, {
    required String message,
    String? title,
    AppFeedbackType type = AppFeedbackType.neutral,
    IconData? icon,
    Color? accentColor,
    Duration duration = const Duration(seconds: 4),
  }) {
    return SnackBar(
      behavior: SnackBarBehavior.floating,
      elevation: 0,
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 18),
      padding: EdgeInsets.zero,
      duration: duration,
      backgroundColor: Colors.transparent,
      content: AppInlineMessage(
        type: type,
        title: title,
        message: message,
        icon: icon,
        accentColor: accentColor,
      ),
    );
  }
}

extension AppFeedbackContextX on BuildContext {
  void showAppSnackBar(
    String message, {
    String? title,
    AppFeedbackType type = AppFeedbackType.neutral,
    IconData? icon,
    Color? accentColor,
    Duration duration = const Duration(seconds: 4),
  }) {
    final messenger = ScaffoldMessenger.maybeOf(this);
    if (messenger == null) {
      return;
    }

    messenger.hideCurrentSnackBar();
    messenger.showSnackBar(
      AppSnackbar.build(
        this,
        message: message,
        title: title,
        type: type,
        icon: icon,
        accentColor: accentColor,
        duration: duration,
      ),
    );
  }
}
