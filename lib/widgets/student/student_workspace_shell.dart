import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../utils/opportunity_dashboard_palette.dart';

class StudentWorkspaceTopBar extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final bool showBackButton;
  final VoidCallback? onBack;
  final List<Widget> actions;
  final EdgeInsetsGeometry margin;
  final double radius;

  const StudentWorkspaceTopBar({
    super.key,
    required this.title,
    required this.subtitle,
    required this.icon,
    this.showBackButton = false,
    this.onBack,
    this.actions = const <Widget>[],
    this.margin = const EdgeInsets.fromLTRB(16, 16, 16, 10),
    this.radius = 24,
  });

  @override
  Widget build(BuildContext context) {
    final compact = MediaQuery.sizeOf(context).width < 720;
    final leading = _TopBarLeadingIcon(
      icon: showBackButton ? Icons.arrow_back_rounded : icon,
      onTap: showBackButton ? onBack : null,
      gradient: showBackButton
          ? const LinearGradient(
              colors: [Color(0xFF0F172A), Color(0xFF1E293B)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            )
          : const LinearGradient(
              colors: [
                OpportunityDashboardPalette.primary,
                OpportunityDashboardPalette.secondary,
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
    );

    return Padding(
      padding: margin,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.94),
          borderRadius: BorderRadius.circular(radius),
          border: Border.all(
            color: OpportunityDashboardPalette.border.withValues(alpha: 0.92),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 28,
              offset: const Offset(0, 14),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
          child: Row(
            children: [
              leading,
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.poppins(
                        fontSize: compact ? 16 : 17,
                        fontWeight: FontWeight.w700,
                        color: OpportunityDashboardPalette.textPrimary,
                      ),
                    ),
                    if (!compact) ...[
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.poppins(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w500,
                          color: OpportunityDashboardPalette.textSecondary,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              if (actions.isNotEmpty) ...[
                const SizedBox(width: 10),
                Row(mainAxisSize: MainAxisSize.min, children: actions),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class StudentWorkspaceAppBar extends StatelessWidget
    implements PreferredSizeWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final bool showBackButton;
  final VoidCallback? onBack;
  final List<Widget> actions;
  final double height;

  const StudentWorkspaceAppBar({
    super.key,
    required this.title,
    required this.subtitle,
    required this.icon,
    this.showBackButton = false,
    this.onBack,
    this.actions = const <Widget>[],
    this.height = 88,
  });

  @override
  Size get preferredSize => Size.fromHeight(height);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      toolbarHeight: height,
      automaticallyImplyLeading: false,
      backgroundColor: Colors.transparent,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      titleSpacing: 0,
      title: StudentWorkspaceTopBar(
        title: title,
        subtitle: subtitle,
        icon: icon,
        showBackButton: showBackButton,
        onBack: onBack,
        actions: actions,
        margin: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      ),
    );
  }
}

class StudentWorkspaceActionButton extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final VoidCallback? onTap;
  final int badgeCount;
  final Color color;

  const StudentWorkspaceActionButton({
    super.key,
    required this.icon,
    required this.tooltip,
    this.onTap,
    this.badgeCount = 0,
    this.color = OpportunityDashboardPalette.textPrimary,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: Padding(
        padding: const EdgeInsets.only(left: 8),
        child: Material(
          color: const Color(0xFFF8FAFF),
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
                  Icon(icon, color: color, size: 22),
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
                          color: OpportunityDashboardPalette.accent,
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Text(
                          badgeCount > 9 ? '9+' : '$badgeCount',
                          style: GoogleFonts.poppins(
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
      ),
    );
  }
}

class StudentWorkspaceNavDestination {
  final String label;
  final String compactLabel;
  final IconData icon;
  final IconData activeIcon;

  const StudentWorkspaceNavDestination({
    required this.label,
    required this.compactLabel,
    required this.icon,
    required this.activeIcon,
  });
}

class StudentPillNavigationBar extends StatelessWidget {
  final List<StudentWorkspaceNavDestination> destinations;
  final int currentIndex;
  final ValueChanged<int> onTap;

  const StudentPillNavigationBar({
    super.key,
    required this.destinations,
    required this.currentIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final compact = width < 370;
    final selectedFlex = compact ? 13 : 11;
    final idleFlex = 5;

    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 5),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.96),
          borderRadius: BorderRadius.circular(28),
          border: Border.all(
            color: OpportunityDashboardPalette.border.withValues(alpha: 0.92),
          ),
          boxShadow: [
            BoxShadow(
              color: OpportunityDashboardPalette.primary.withValues(
                alpha: 0.10,
              ),
              blurRadius: 24,
              offset: const Offset(0, 12),
            ),
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: Row(
          children: List<Widget>.generate(
            destinations.length,
            (index) => Flexible(
              flex: currentIndex == index ? selectedFlex : idleFlex,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 2),
                child: _StudentPillNavItem(
                  destination: destinations[index],
                  selected: currentIndex == index,
                  compact: compact,
                  onTap: () => onTap(index),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _TopBarLeadingIcon extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onTap;
  final Gradient gradient;

  const _TopBarLeadingIcon({
    required this.icon,
    required this.onTap,
    required this.gradient,
  });

  @override
  Widget build(BuildContext context) {
    final child = Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        gradient: gradient,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Icon(icon, color: Colors.white, size: 22),
    );

    if (onTap == null) {
      return child;
    }

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: child,
      ),
    );
  }
}

class _StudentPillNavItem extends StatelessWidget {
  final StudentWorkspaceNavDestination destination;
  final bool selected;
  final bool compact;
  final VoidCallback onTap;

  const _StudentPillNavItem({
    required this.destination,
    required this.selected,
    required this.compact,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final label = compact ? destination.compactLabel : destination.label;
    const selectedGradient = LinearGradient(
      colors: [
        OpportunityDashboardPalette.primary,
        OpportunityDashboardPalette.primaryDark,
      ],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    );

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(22),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOutCubic,
        height: 46,
        padding: EdgeInsets.symmetric(
          horizontal: selected ? (compact ? 4 : 6) : 0,
        ),
        decoration: BoxDecoration(
          gradient: selected ? selectedGradient : null,
          color: selected ? null : Colors.transparent,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(
            color: selected
                ? Colors.white.withValues(alpha: 0.18)
                : Colors.transparent,
          ),
          boxShadow: selected
              ? [
                  BoxShadow(
                    color: OpportunityDashboardPalette.primary.withValues(
                      alpha: 0.22,
                    ),
                    blurRadius: 16,
                    offset: const Offset(0, 8),
                  ),
                ]
              : null,
        ),
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 200),
          switchInCurve: Curves.easeOutCubic,
          switchOutCurve: Curves.easeOutCubic,
          child: selected
              ? Row(
                  key: ValueKey<String>('selected-${destination.label}'),
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      destination.activeIcon,
                      size: compact ? 15 : 17,
                      color: Colors.white,
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: Alignment.centerLeft,
                        child: Text(
                          label,
                          maxLines: 1,
                          softWrap: false,
                          style: GoogleFonts.poppins(
                            fontSize: compact ? 8.7 : 9.8,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ],
                )
              : Center(
                  key: ValueKey<String>('idle-${destination.label}'),
                  child: Icon(
                    destination.icon,
                    size: compact ? 17 : 19,
                    color: OpportunityDashboardPalette.textSecondary.withValues(
                      alpha: 0.88,
                    ),
                  ),
                ),
        ),
      ),
    );
  }
}
