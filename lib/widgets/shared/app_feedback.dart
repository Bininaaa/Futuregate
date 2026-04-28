import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

enum AppFeedbackType { error, warning, success, info, neutral, removed }

@immutable
class AppFeedbackTheme extends ThemeExtension<AppFeedbackTheme> {
  final Color info;
  final Color success;
  final Color warning;
  final Color error;
  final Color neutral;
  final Color removed;

  const AppFeedbackTheme({
    required this.info,
    required this.success,
    required this.warning,
    required this.error,
    required this.neutral,
    required this.removed,
  });

  factory AppFeedbackTheme.fallback(ColorScheme colorScheme) {
    return AppFeedbackTheme(
      info: colorScheme.primary,
      success: const Color(0xFF179D6C),
      warning: const Color(0xFFD97706),
      error: colorScheme.error,
      neutral: const Color(0xFF475569),
      removed: const Color(0xFF7C3AED),
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
    final strong =
        type == AppFeedbackType.success || type == AppFeedbackType.removed;
    final base =
        accentColor ??
        switch (type) {
          AppFeedbackType.error => error,
          AppFeedbackType.warning => warning,
          AppFeedbackType.success => success,
          AppFeedbackType.info => info,
          AppFeedbackType.neutral => neutral,
          AppFeedbackType.removed => removed,
        };

    return AppFeedbackVariant(
      accent: base,
      background: strong ? base : _blend(base, surface, 0.08),
      surfaceHighlight: strong
          ? Color.alphaBlend(Colors.white.withValues(alpha: 0.12), base)
          : _blend(base, surface, 0.03),
      border: strong
          ? Color.alphaBlend(Colors.white.withValues(alpha: 0.28), base)
          : _blend(base, surface, 0.18),
      shadow: base.withValues(alpha: strong ? 0.30 : 0.10),
      iconBackground: strong
          ? Colors.white.withValues(alpha: 0.20)
          : _blend(base, surface, 0.13),
      titleColor: strong ? Colors.white : onSurface,
      messageColor: strong
          ? Colors.white.withValues(alpha: 0.88)
          : onSurface.withValues(alpha: 0.74),
      actionColor: base,
      icon: switch (type) {
        AppFeedbackType.error => Icons.error_outline_rounded,
        AppFeedbackType.warning => Icons.warning_amber_rounded,
        AppFeedbackType.success => Icons.check_circle_outline_rounded,
        AppFeedbackType.info => Icons.info_outline_rounded,
        AppFeedbackType.neutral => Icons.chat_bubble_outline_rounded,
        AppFeedbackType.removed => Icons.undo_rounded,
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
    Color? removed,
  }) {
    return AppFeedbackTheme(
      info: info ?? this.info,
      success: success ?? this.success,
      warning: warning ?? this.warning,
      error: error ?? this.error,
      neutral: neutral ?? this.neutral,
      removed: removed ?? this.removed,
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
      removed: Color.lerp(removed, other.removed, t) ?? removed,
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
          horizontal: compact ? 13 : 15,
          vertical: compact ? 11 : 13,
        );
    final effectiveIcon = icon ?? variant.icon;
    final hasTitle = (title ?? '').trim().isNotEmpty;
    final centerSimpleMessage = !hasTitle && action == null && trailing == null;

    return Container(
      width: double.infinity,
      padding: effectivePadding,
      decoration: BoxDecoration(
        gradient:
            type == AppFeedbackType.success || type == AppFeedbackType.removed
            ? LinearGradient(
                colors: <Color>[variant.background, variant.surfaceHighlight],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              )
            : null,
        color:
            type == AppFeedbackType.success || type == AppFeedbackType.removed
            ? null
            : variant.background,
        borderRadius: BorderRadius.circular(compact ? 18 : 20),
        border: Border.all(
          color:
              type == AppFeedbackType.success || type == AppFeedbackType.removed
              ? Colors.white.withValues(alpha: 0.30)
              : variant.accent.withValues(alpha: 0.22),
        ),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: variant.shadow,
            blurRadius:
                type == AppFeedbackType.success ||
                    type == AppFeedbackType.removed
                ? (compact ? 24 : 30)
                : (compact ? 16 : 22),
            offset: Offset(
              0,
              type == AppFeedbackType.success || type == AppFeedbackType.removed
                  ? (compact ? 9 : 12)
                  : (compact ? 6 : 8),
            ),
          ),
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: centerSimpleMessage
            ? CrossAxisAlignment.center
            : CrossAxisAlignment.start,
        children: <Widget>[
          if (showIcon) ...<Widget>[
            Container(
              width: compact ? 38 : 42,
              height: compact ? 38 : 42,
              decoration: BoxDecoration(
                color:
                    type == AppFeedbackType.success ||
                        type == AppFeedbackType.removed
                    ? variant.iconBackground
                    : variant.accent,
                shape: BoxShape.circle,
              ),
              child: Icon(
                effectiveIcon,
                color: Colors.white,
                size: compact ? 18 : 20,
              ),
            ),
            SizedBox(width: compact ? 11 : 13),
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
                      fontSize: compact ? 12.8 : 13.6,
                      fontWeight: FontWeight.w700,
                      color:
                          type == AppFeedbackType.success ||
                              type == AppFeedbackType.removed
                          ? variant.titleColor
                          : variant.accent,
                    ),
                  ),
                if (hasTitle) const SizedBox(height: 3),
                Text(
                  message,
                  style: GoogleFonts.poppins(
                    fontSize: compact ? 11.8 : 12.4,
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
      margin: const EdgeInsets.fromLTRB(14, 0, 14, 20),
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
