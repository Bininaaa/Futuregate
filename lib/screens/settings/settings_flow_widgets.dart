import 'package:flutter/material.dart';

import '../../widgets/app_shell_background.dart';
import '../../widgets/shared/app_feedback.dart';
import 'settings_flow_theme.dart';

class SettingsPageScaffold extends StatelessWidget {
  final String title;
  final Widget child;
  final List<Widget>? actions;
  final Widget? leading;
  final Color? backgroundColor;
  final bool centerTitle;
  final EdgeInsetsGeometry bodyPadding;

  const SettingsPageScaffold({
    super.key,
    required this.title,
    required this.child,
    this.actions,
    this.leading,
    this.backgroundColor,
    this.centerTitle = false,
    this.bodyPadding = const EdgeInsets.fromLTRB(16, 12, 16, 28),
  });

  @override
  Widget build(BuildContext context) {
    final canPop = Navigator.of(context).canPop();

    return AppShellBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          automaticallyImplyLeading: false,
          centerTitle: centerTitle,
          backgroundColor: Colors.transparent,
          surfaceTintColor: Colors.transparent,
          elevation: 0,
          scrolledUnderElevation: 0,
          leading:
              leading ??
              (canPop
                  ? IconButton(
                      onPressed: () => Navigator.maybePop(context),
                      icon: const Icon(
                        Icons.arrow_back_ios_new_rounded,
                        color: SettingsFlowPalette.textPrimary,
                      ),
                    )
                  : null),
          title: Text(title, style: SettingsFlowTheme.appBarTitle()),
          actions: actions,
        ),
        body: SafeArea(
          top: false,
          child: SingleChildScrollView(padding: bodyPadding, child: child),
        ),
      ),
    );
  }
}

class SettingsSectionHeading extends StatelessWidget {
  final String title;
  final String? subtitle;
  final Widget? trailing;

  const SettingsSectionHeading({
    super.key,
    required this.title,
    this.subtitle,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final stackTrailing = trailing != null && constraints.maxWidth < 360;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (!stackTrailing)
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(title, style: SettingsFlowTheme.sectionTitle()),
                        if (subtitle != null) ...[
                          const SizedBox(height: 4),
                          Text(subtitle!, style: SettingsFlowTheme.caption()),
                        ],
                      ],
                    ),
                  ),
                  if (trailing != null) ...[
                    const SizedBox(width: 10),
                    trailing!,
                  ],
                ],
              )
            else ...[
              Text(title, style: SettingsFlowTheme.sectionTitle()),
              if (subtitle != null) ...[
                const SizedBox(height: 4),
                Text(subtitle!, style: SettingsFlowTheme.caption()),
              ],
              const SizedBox(height: 10),
              trailing!,
            ],
          ],
        );
      },
    );
  }
}

class SettingsPanel extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final Color? color;
  final Border? border;

  const SettingsPanel({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.color,
    this.border,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: color ?? SettingsFlowPalette.surface,
        borderRadius: SettingsFlowTheme.radius(24),
        border: border ?? Border.all(color: SettingsFlowPalette.border),
        boxShadow: SettingsFlowTheme.softShadow(),
      ),
      padding: padding,
      child: child,
    );
  }
}

class SettingsIconBox extends StatelessWidget {
  final IconData icon;
  final Color color;
  final Color? backgroundColor;
  final double size;

  const SettingsIconBox({
    super.key,
    required this.icon,
    required this.color,
    this.backgroundColor,
    this.size = 18,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: backgroundColor ?? color.withValues(alpha: 0.12),
        borderRadius: SettingsFlowTheme.radius(14),
      ),
      child: Icon(icon, color: color, size: size),
    );
  }
}

class SettingsListRow extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String? subtitle;
  final Widget? trailing;
  final VoidCallback? onTap;
  final bool destructive;

  const SettingsListRow({
    super.key,
    required this.icon,
    required this.iconColor,
    required this.title,
    this.subtitle,
    this.trailing,
    this.onTap,
    this.destructive = false,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveTextColor = destructive
        ? SettingsFlowPalette.error
        : SettingsFlowPalette.textPrimary;

    return InkWell(
      onTap: onTap,
      borderRadius: SettingsFlowTheme.radius(20),
      child: Ink(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: SettingsFlowPalette.surface,
          borderRadius: SettingsFlowTheme.radius(20),
          border: Border.all(color: SettingsFlowPalette.border),
        ),
        child: Row(
          children: [
            SettingsIconBox(
              icon: icon,
              color: iconColor,
              backgroundColor: destructive
                  ? SettingsFlowPalette.error.withValues(alpha: 0.10)
                  : iconColor.withValues(alpha: 0.12),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: SettingsFlowTheme.cardTitle(effectiveTextColor),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (subtitle != null) ...[
                    const SizedBox(height: 3),
                    Text(
                      subtitle!,
                      style: SettingsFlowTheme.caption(
                        destructive
                            ? SettingsFlowPalette.error.withValues(alpha: 0.8)
                            : SettingsFlowPalette.textSecondary,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(width: 8),
            trailing ??
                Icon(
                  Icons.chevron_right_rounded,
                  color: effectiveTextColor.withValues(alpha: 0.42),
                  size: 22,
                ),
          ],
        ),
      ),
    );
  }
}

class SettingsPrimaryButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final Color? backgroundColor;
  final Color? foregroundColor;

  const SettingsPrimaryButton({
    super.key,
    required this.label,
    this.onPressed,
    this.icon,
    this.backgroundColor,
    this.foregroundColor,
  });

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        elevation: 0,
        minimumSize: const Size.fromHeight(50),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        backgroundColor: backgroundColor ?? SettingsFlowPalette.primary,
        foregroundColor: foregroundColor ?? Colors.white,
        disabledBackgroundColor:
            (backgroundColor ?? SettingsFlowPalette.primary).withValues(
              alpha: 0.4,
            ),
        shape: RoundedRectangleBorder(
          borderRadius: SettingsFlowTheme.radius(18),
        ),
      ),
      child: FittedBox(
        fit: BoxFit.scaleDown,
        child: icon == null
            ? Text(label, style: SettingsFlowTheme.body(Colors.white))
            : Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(icon, size: 16),
                  const SizedBox(width: 6),
                  Text(label, style: SettingsFlowTheme.body(Colors.white)),
                ],
              ),
      ),
    );
  }
}

class SettingsSecondaryButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final Color? color;

  const SettingsSecondaryButton({
    super.key,
    required this.label,
    this.onPressed,
    this.icon,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveColor = color ?? SettingsFlowPalette.textPrimary;

    return OutlinedButton(
      onPressed: onPressed,
      style: OutlinedButton.styleFrom(
        minimumSize: const Size.fromHeight(50),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        foregroundColor: effectiveColor,
        side: BorderSide(color: SettingsFlowPalette.border),
        shape: RoundedRectangleBorder(
          borderRadius: SettingsFlowTheme.radius(18),
        ),
      ),
      child: FittedBox(
        fit: BoxFit.scaleDown,
        child: icon == null
            ? Text(label, style: SettingsFlowTheme.body(effectiveColor))
            : Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(icon, size: 16),
                  const SizedBox(width: 6),
                  Text(label, style: SettingsFlowTheme.body(effectiveColor)),
                ],
              ),
      ),
    );
  }
}

class SettingsButtonGroup extends StatelessWidget {
  final List<Widget> children;
  final double spacing;
  final double breakpoint;

  const SettingsButtonGroup({
    super.key,
    required this.children,
    this.spacing = 10,
    this.breakpoint = 360,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < breakpoint) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              for (int index = 0; index < children.length; index++) ...[
                children[index],
                if (index != children.length - 1) SizedBox(height: spacing),
              ],
            ],
          );
        }

        return Row(
          children: [
            for (int index = 0; index < children.length; index++) ...[
              Expanded(child: children[index]),
              if (index != children.length - 1) SizedBox(width: spacing),
            ],
          ],
        );
      },
    );
  }
}

class SettingsAdaptiveHeader extends StatelessWidget {
  final Widget leading;
  final Widget content;
  final double spacing;
  final double breakpoint;

  const SettingsAdaptiveHeader({
    super.key,
    required this.leading,
    required this.content,
    this.spacing = 12,
    this.breakpoint = 360,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < breakpoint) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              leading,
              SizedBox(height: spacing),
              content,
            ],
          );
        }

        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            leading,
            SizedBox(width: spacing),
            Expanded(child: content),
          ],
        );
      },
    );
  }
}

class SettingsStatusPill extends StatelessWidget {
  final String label;
  final Color color;

  const SettingsStatusPill({
    super.key,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: SettingsFlowTheme.radius(999),
      ),
      child: Text(
        label,
        style: SettingsFlowTheme.micro(color),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }
}

class SettingsInfoBanner extends StatelessWidget {
  final IconData icon;
  final String title;
  final String message;
  final Color color;

  const SettingsInfoBanner({
    super.key,
    required this.icon,
    required this.title,
    required this.message,
    this.color = SettingsFlowPalette.primary,
  });

  @override
  Widget build(BuildContext context) {
    return AppInlineMessage(
      type: AppFeedbackType.info,
      title: title,
      message: message,
      icon: icon,
      accentColor: color,
    );
  }
}

class SettingsEmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String message;

  const SettingsEmptyState({
    super.key,
    required this.icon,
    required this.title,
    required this.message,
  });

  @override
  Widget build(BuildContext context) {
    return AppEmptyStateNotice(
      type: AppFeedbackType.neutral,
      icon: icon,
      title: title,
      message: message,
      accentColor: SettingsFlowPalette.primary,
      padding: const EdgeInsets.fromLTRB(22, 24, 22, 22),
    );
  }
}
