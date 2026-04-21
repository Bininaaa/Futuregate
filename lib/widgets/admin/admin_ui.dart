import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_typography.dart';
import '../../utils/admin_palette.dart';
import '../../utils/display_text.dart';
import '../shared/app_feedback.dart';

class AdminShellBackground extends StatelessWidget {
  final Widget child;

  const AdminShellBackground({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    AppColors.of(context);

    return DecoratedBox(
      decoration: BoxDecoration(gradient: AdminPalette.shellGradient),
      child: Stack(
        children: [
          Positioned(
            top: -120,
            right: -40,
            child: _GlowOrb(
              size: 240,
              color: AdminPalette.primary.withValues(alpha: 0.08),
            ),
          ),
          Positioned(
            left: -80,
            bottom: -120,
            child: _GlowOrb(
              size: 220,
              color: AdminPalette.secondary.withValues(alpha: 0.08),
            ),
          ),
          child,
        ],
      ),
    );
  }
}

class AdminSurface extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final EdgeInsetsGeometry? margin;
  final Color? color;
  final double radius;
  final Gradient? gradient;
  final Border? border;
  final List<BoxShadow>? boxShadow;

  const AdminSurface({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.margin,
    this.color,
    this.radius = 24,
    this.gradient,
    this.border,
    this.boxShadow,
  });

  @override
  Widget build(BuildContext context) {
    final content = Container(
      padding: padding,
      decoration: BoxDecoration(
        color: color ?? AdminPalette.surface,
        gradient: gradient,
        borderRadius: BorderRadius.circular(radius),
        border:
            border ??
            Border.all(color: AdminPalette.border.withValues(alpha: 0.9)),
        boxShadow: boxShadow ?? AdminPalette.softShadow,
      ),
      child: child,
    );

    if (margin == null) {
      return content;
    }

    return Padding(padding: margin!, child: content);
  }
}

class AdminSectionHeader extends StatelessWidget {
  final String title;
  final String? subtitle;
  final String? eyebrow;
  final Widget? trailing;

  const AdminSectionHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.eyebrow,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if ((eyebrow ?? '').trim().isNotEmpty)
                Text(
                  eyebrow!,
                  style: AppTypography.product(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.9,
                    color: AdminPalette.primary,
                  ),
                ),
              Text(
                title,
                style: AppTypography.product(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: AdminPalette.textPrimary,
                ),
              ),
              if ((subtitle ?? '').trim().isNotEmpty) ...[
                const SizedBox(height: 4),
                Text(
                  subtitle!,
                  style: AppTypography.product(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w500,
                    color: AdminPalette.textMuted,
                    height: 1.45,
                  ),
                ),
              ],
            ],
          ),
        ),
        if (trailing != null) ...[const SizedBox(width: 12), trailing!],
      ],
    );
  }
}

class AdminHeroCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color? accentColor;
  final List<AdminHeroStat> stats;
  final List<Widget> actions;

  const AdminHeroCard({
    super.key,
    required this.title,
    required this.subtitle,
    required this.icon,
    this.accentColor,
    this.stats = const [],
    this.actions = const [],
  });

  @override
  Widget build(BuildContext context) {
    return AdminSurface(
      padding: const EdgeInsets.all(18),
      gradient: AdminPalette.heroGradient(
        accentColor ?? AdminPalette.secondary,
      ),
      border: Border.all(color: Colors.white.withValues(alpha: 0.14)),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isCompact = constraints.maxWidth < 420;

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (isCompact) ...[
                _HeroIcon(icon: icon),
                const SizedBox(height: 16),
              ],
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: AppTypography.product(
                            fontSize: isCompact ? 19 : 22,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                            height: 1.15,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          subtitle,
                          style: AppTypography.product(
                            fontSize: isCompact ? 11.8 : 12.4,
                            fontWeight: FontWeight.w500,
                            color: Colors.white.withValues(alpha: 0.86),
                            height: 1.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (!isCompact) ...[
                    const SizedBox(width: 16),
                    _HeroIcon(icon: icon),
                  ],
                ],
              ),
              if (stats.isNotEmpty) ...[
                const SizedBox(height: 16),
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: stats
                      .map(
                        (stat) => _HeroStatChip(
                          label: stat.label,
                          value: stat.value,
                          color: stat.color,
                        ),
                      )
                      .toList(),
                ),
              ],
              if (actions.isNotEmpty) ...[
                const SizedBox(height: 14),
                Wrap(spacing: 6, runSpacing: 6, children: actions),
              ],
            ],
          );
        },
      ),
    );
  }
}

class AdminHeroStat {
  final String label;
  final String value;
  final Color color;

  const AdminHeroStat({
    required this.label,
    required this.value,
    this.color = Colors.white,
  });
}

class AdminActionChip extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback? onTap;
  final bool filled;
  final Color color;

  const AdminActionChip({
    super.key,
    required this.label,
    required this.icon,
    this.onTap,
    this.filled = false,
    this.color = Colors.white,
  });

  @override
  Widget build(BuildContext context) {
    final background = filled
        ? AdminPalette.isDark
              ? AdminPalette.surfaceElevated.withValues(alpha: 0.96)
              : Colors.white
        : Colors.white.withValues(alpha: 0.1);
    final foreground = filled
        ? AdminPalette.isDark
              ? AdminPalette.textPrimary
              : AdminPalette.primaryDark
        : color;
    final borderColor = filled
        ? AdminPalette.isDark
              ? AdminPalette.border.withValues(alpha: 0.82)
              : Colors.white.withValues(alpha: 0.25)
        : Colors.white.withValues(alpha: 0.14);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(999),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: background,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: borderColor),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 15, color: foreground),
            const SizedBox(width: 6),
            Text(
              label,
              style: AppTypography.product(
                fontSize: 11.5,
                fontWeight: FontWeight.w600,
                color: foreground,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class AdminSearchField extends StatelessWidget {
  final TextEditingController controller;
  final ValueChanged<String>? onChanged;
  final String hintText;
  final IconData prefixIcon;
  final VoidCallback? onClear;

  const AdminSearchField({
    super.key,
    required this.controller,
    required this.hintText,
    this.onChanged,
    this.prefixIcon = Icons.search_rounded,
    this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    return AdminSurface(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      radius: 20,
      color: AdminPalette.surface,
      boxShadow: [
        BoxShadow(
          color: AdminPalette.primary.withValues(alpha: 0.05),
          blurRadius: 18,
          offset: const Offset(0, 10),
        ),
      ],
      child: TextField(
        controller: controller,
        onChanged: onChanged,
        style: AppTypography.product(
          fontSize: 13,
          fontWeight: FontWeight.w500,
          color: AdminPalette.textPrimary,
        ),
        decoration: InputDecoration(
          hintText: hintText,
          hintStyle: AppTypography.product(
            fontSize: 12.5,
            fontWeight: FontWeight.w500,
            color: AdminPalette.textMuted,
          ),
          border: InputBorder.none,
          prefixIcon: Icon(prefixIcon, color: AdminPalette.primary),
          suffixIcon: controller.text.trim().isEmpty
              ? null
              : IconButton(
                  onPressed: onClear,
                  icon: Icon(
                    Icons.close_rounded,
                    color: AdminPalette.textMuted,
                  ),
                ),
        ),
      ),
    );
  }
}

class AdminFilterChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback? onTap;
  final IconData? icon;
  final int? badgeCount;
  final bool enabled;

  const AdminFilterChip({
    super.key,
    required this.label,
    required this.selected,
    this.onTap,
    this.icon,
    this.badgeCount,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    final background = !enabled
        ? selected
              ? AdminPalette.primarySoft
              : AdminPalette.surfaceMuted
        : selected
        ? AdminPalette.primary
        : AdminPalette.surface;
    final foreground = !enabled
        ? selected
              ? AdminPalette.primary
              : AdminPalette.textMuted
        : selected
        ? Colors.white
        : AdminPalette.textSecondary;
    final borderColor = !enabled
        ? selected
              ? AdminPalette.primary.withValues(alpha: 0.18)
              : AdminPalette.border.withValues(alpha: 0.9)
        : selected
        ? Colors.transparent
        : AdminPalette.border.withValues(alpha: 0.92);

    return InkWell(
      onTap: enabled ? onTap : null,
      borderRadius: BorderRadius.circular(999),
      child: Opacity(
        opacity: enabled ? 1 : 0.55,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOutCubic,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: background,
            borderRadius: BorderRadius.circular(999),
            border: Border.all(color: borderColor),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (icon != null) ...[
                Icon(icon, size: 15, color: foreground),
                const SizedBox(width: 7),
              ],
              Text(
                label,
                style: AppTypography.product(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: foreground,
                ),
              ),
              if ((badgeCount ?? 0) > 0) ...[
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: selected
                        ? Colors.white.withValues(alpha: 0.18)
                        : AdminPalette.primarySoft,
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    '${badgeCount!}',
                    style: AppTypography.product(
                      fontSize: 10.5,
                      fontWeight: FontWeight.w700,
                      color: selected ? Colors.white : AdminPalette.primary,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class AdminPill extends StatelessWidget {
  final String label;
  final Color color;
  final IconData? icon;

  const AdminPill({
    super.key,
    required this.label,
    required this.color,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final displayLabel = DisplayText.capitalizeLeadingLabel(label);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 12, color: color),
            const SizedBox(width: 6),
          ],
          Text(
            displayLabel,
            style: AppTypography.product(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

class _GlowOrb extends StatelessWidget {
  final double size;
  final Color color;

  const _GlowOrb({required this.size, required this.color});

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(color: color, shape: BoxShape.circle),
      ),
    );
  }
}

class AdminIconActionButton extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final VoidCallback? onTap;
  final int badgeCount;
  final Color? color;

  const AdminIconActionButton({
    super.key,
    required this.icon,
    required this.tooltip,
    this.onTap,
    this.badgeCount = 0,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: Material(
        color: AdminPalette.surface.withValues(alpha: 0.94),
        borderRadius: BorderRadius.circular(18),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(18),
          child: SizedBox(
            width: 48,
            height: 48,
            child: Stack(
              alignment: Alignment.center,
              children: [
                Icon(icon, color: color ?? AdminPalette.textPrimary, size: 22),
                if (badgeCount > 0)
                  Positioned(
                    top: 8,
                    right: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 5,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: AdminPalette.accent,
                        borderRadius: BorderRadius.circular(999),
                        border: Border.all(
                          color: AdminPalette.surface.withValues(alpha: 0.94),
                          width: 1.5,
                        ),
                      ),
                      child: Text(
                        badgeCount > 9 ? '9+' : '$badgeCount',
                        style: AppTypography.product(
                          fontSize: 9.5,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class AdminEmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String message;
  final Widget? action;

  const AdminEmptyState({
    super.key,
    required this.icon,
    required this.title,
    required this.message,
    this.action,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: AppEmptyStateNotice(
          type: AppFeedbackType.neutral,
          icon: icon,
          title: title,
          message: message,
          accentColor: AdminPalette.primary,
          action: action,
          padding: const EdgeInsets.fromLTRB(24, 26, 24, 22),
        ),
      ),
    );
  }
}

class _HeroIcon extends StatelessWidget {
  final IconData icon;

  const _HeroIcon({required this.icon});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 54,
      height: 54,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Icon(icon, color: Colors.white, size: 26),
    );
  }
}

class _HeroStatChip extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _HeroStatChip({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minWidth: 96),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.11),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            value,
            style: AppTypography.product(
              fontSize: 16.5,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            label,
            style: AppTypography.product(
              fontSize: 10.5,
              fontWeight: FontWeight.w500,
              color: Colors.white.withValues(alpha: 0.84),
            ),
          ),
        ],
      ),
    );
  }
}
