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
    final compact = width < 400;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Color.alphaBlend(
                OpportunityDashboardPalette.primaryDark.withValues(alpha: 0.34),
                const Color(0xFF090C14),
              ),
              const Color(0xFF090C14),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(34),
          border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
          boxShadow: [
            BoxShadow(
              color: OpportunityDashboardPalette.primary.withValues(
                alpha: 0.14,
              ),
              blurRadius: 26,
              offset: const Offset(0, 14),
            ),
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.18),
              blurRadius: 18,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Row(
          children: List<Widget>.generate(
            destinations.length,
            (index) => Flexible(
              flex: currentIndex == index ? (compact ? 14 : 15) : 6,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 3),
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
    final selectedBackground = Color.alphaBlend(
      OpportunityDashboardPalette.primary.withValues(alpha: 0.12),
      const Color(0xFF2B2B2E),
    );

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(999),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOutCubic,
        height: 48,
        padding: EdgeInsets.symmetric(
          horizontal: selected ? (compact ? 8 : 10) : 0,
        ),
        decoration: BoxDecoration(
          color: selected ? selectedBackground : Colors.transparent,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
            color: selected
                ? Colors.white.withValues(alpha: 0.06)
                : Colors.transparent,
          ),
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
                    Container(
                      width: compact ? 20 : 24,
                      height: compact ? 20 : 24,
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        destination.activeIcon,
                        size: compact ? 11 : 14,
                        color: const Color(0xFF090C14),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Flexible(
                      child: Text(
                        label,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.poppins(
                          fontSize: compact ? 9.4 : 11.2,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                )
              : Center(
                  key: ValueKey<String>('idle-${destination.label}'),
                  child: Icon(
                    destination.icon,
                    size: compact ? 18 : 21,
                    color: Colors.white.withValues(alpha: 0.88),
                  ),
                ),
        ),
      ),
    );
  }
}
