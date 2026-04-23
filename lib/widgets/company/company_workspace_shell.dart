import 'package:flutter/material.dart';
import '../../l10n/generated/app_localizations.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../models/user_model.dart';
import '../../theme/app_colors.dart';
import '../../utils/company_dashboard_palette.dart';
import '../profile_avatar.dart';
import '../shared/app_nav_scroll_switcher.dart';

class CompanyWorkspaceDestination {
  final String label;
  final String subtitle;
  final IconData icon;
  final IconData activeIcon;

  const CompanyWorkspaceDestination({
    required this.label,
    required this.subtitle,
    required this.icon,
    required this.activeIcon,
  });
}

class CompanyWorkspaceHeaderCard extends StatelessWidget {
  final CompanyWorkspaceDestination destination;
  final UserModel? user;
  final int unreadCount;
  final VoidCallback onNotificationsTap;
  final VoidCallback onProfileTap;
  final VoidCallback? onSettingsTap;

  const CompanyWorkspaceHeaderCard({
    super.key,
    required this.destination,
    required this.user,
    required this.unreadCount,
    required this.onNotificationsTap,
    required this.onProfileTap,
    this.onSettingsTap,
  });

  String _companyLabel(UserModel? user) {
    final companyName = (user?.companyName ?? '').trim();
    if (companyName.isNotEmpty) {
      return companyName;
    }

    final fullName = (user?.fullName ?? '').trim();
    if (fullName.isNotEmpty) {
      return fullName;
    }

    return 'Company account';
  }

  @override
  Widget build(BuildContext context) {
    final compact = MediaQuery.sizeOf(context).width < 420;
    final surface = AppColors.isDark
        ? CompanyDashboardPalette.surfaceElevated.withValues(alpha: 0.97)
        : CompanyDashboardPalette.surface.withValues(alpha: 0.97);

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 15, 16, 15),
      decoration: BoxDecoration(
        color: surface,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(
          color: CompanyDashboardPalette.border.withValues(
            alpha: AppColors.isDark ? 0.92 : 0.86,
          ),
        ),
        boxShadow: [
          BoxShadow(
            color: CompanyDashboardPalette.primary.withValues(
              alpha: AppColors.isDark ? 0.16 : 0.10,
            ),
            blurRadius: 28,
            offset: const Offset(0, 14),
          ),
          BoxShadow(
            color: AppColors.current.shadow.withValues(
              alpha: AppColors.isDark ? 0.24 : 0.06,
            ),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CompanyWorkspaceProfileButton(
                user: user,
                onTap: onProfileTap,
                size: 50,
                borderRadius: 20,
                avatarRadius: 19,
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      destination.label,
                      style: GoogleFonts.poppins(
                        fontSize: compact ? 18 : 20,
                        fontWeight: FontWeight.w700,
                        color: CompanyDashboardPalette.textPrimary,
                        height: 1.1,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      destination.subtitle,
                      maxLines: compact ? 2 : 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: CompanyDashboardPalette.textMuted,
                        height: 1.45,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CompanyWorkspaceActionButton(
                    icon: Icons.notifications_outlined,
                    tooltip: AppLocalizations.of(context)!.uiNotifications,
                    badgeCount: unreadCount,
                    onTap: onNotificationsTap,
                  ),
                  if (onSettingsTap != null) ...[
                    const SizedBox(width: 8),
                    CompanyWorkspaceActionButton(
                      icon: Icons.settings_outlined,
                      tooltip: AppLocalizations.of(context)!.uiSettings,
                      onTap: onSettingsTap,
                    ),
                  ],
                ],
              ),
            ],
          ),
          const SizedBox(height: 14),
          _WorkspaceMetaPill(
            icon: Icons.apartment_rounded,
            label: _companyLabel(user),
          ),
        ],
      ),
    );
  }
}

class CompanyWorkspaceTopBar extends StatelessWidget {
  final CompanyWorkspaceDestination destination;
  final UserModel? user;
  final int unreadCount;
  final VoidCallback onNotificationsTap;
  final VoidCallback onProfileTap;
  final VoidCallback? onSettingsTap;
  final EdgeInsetsGeometry margin;
  final double radius;

  const CompanyWorkspaceTopBar({
    super.key,
    required this.destination,
    required this.user,
    required this.unreadCount,
    required this.onNotificationsTap,
    required this.onProfileTap,
    this.onSettingsTap,
    this.margin = const EdgeInsets.fromLTRB(16, 16, 16, 10),
    this.radius = 22,
  });

  @override
  Widget build(BuildContext context) {
    final compact = MediaQuery.sizeOf(context).width < 720;
    final surface = AppColors.isDark
        ? CompanyDashboardPalette.surfaceElevated.withValues(alpha: 0.96)
        : CompanyDashboardPalette.surface.withValues(alpha: 0.96);

    return Padding(
      padding: margin,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: surface,
          borderRadius: BorderRadius.circular(radius),
          border: Border.all(
            color: CompanyDashboardPalette.border.withValues(
              alpha: AppColors.isDark ? 0.94 : 0.86,
            ),
          ),
          boxShadow: [
            BoxShadow(
              color: CompanyDashboardPalette.primary.withValues(
                alpha: AppColors.isDark ? 0.16 : 0.10,
              ),
              blurRadius: 24,
              offset: const Offset(0, 12),
            ),
            BoxShadow(
              color: AppColors.current.shadow.withValues(
                alpha: AppColors.isDark ? 0.24 : 0.06,
              ),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
          child: Row(
            children: [
              CompanyWorkspaceProfileButton(
                user: user,
                onTap: onProfileTap,
                size: 44,
                borderRadius: 18,
                avatarRadius: 16,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      destination.label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.poppins(
                        fontSize: compact ? 16 : 17,
                        fontWeight: FontWeight.w700,
                        color: CompanyDashboardPalette.textPrimary,
                        height: 1.1,
                      ),
                    ),
                    if (!compact) ...[
                      const SizedBox(height: 2),
                      Text(
                        destination.subtitle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.poppins(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w500,
                          color: CompanyDashboardPalette.textMuted,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 10),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CompanyWorkspaceActionButton(
                    icon: Icons.notifications_outlined,
                    tooltip: AppLocalizations.of(context)!.uiNotifications,
                    badgeCount: unreadCount,
                    onTap: onNotificationsTap,
                  ),
                  if (onSettingsTap != null) ...[
                    const SizedBox(width: 8),
                    CompanyWorkspaceActionButton(
                      icon: Icons.settings_outlined,
                      tooltip: AppLocalizations.of(context)!.uiSettings,
                      onTap: onSettingsTap,
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class CompanyWorkspaceTabBar extends StatelessWidget {
  final List<CompanyWorkspaceDestination> destinations;
  final int currentIndex;
  final ValueChanged<int> onTap;

  const CompanyWorkspaceTabBar({
    super.key,
    required this.destinations,
    required this.currentIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 62,
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.isDark
            ? CompanyDashboardPalette.surfaceElevated.withValues(alpha: 0.95)
            : CompanyDashboardPalette.surface.withValues(alpha: 0.95),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: CompanyDashboardPalette.border.withValues(
            alpha: AppColors.isDark ? 0.90 : 0.84,
          ),
        ),
      ),
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        itemCount: destinations.length,
        separatorBuilder: (_, _) => const SizedBox(width: 6),
        itemBuilder: (context, index) {
          final destination = destinations[index];
          final selected = index == currentIndex;

          return Semantics(
            button: true,
            selected: selected,
            label: destination.label,
            child: Tooltip(
              message: destination.label,
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () => onTap(index),
                  borderRadius: BorderRadius.circular(18),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 220),
                    curve: Curves.easeOutCubic,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      gradient: selected
                          ? const LinearGradient(
                              colors: [
                                Color(0xFF155E75),
                                Color(0xFF0891B2),
                                Color(0xFF2563EB),
                              ],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            )
                          : null,
                      color: selected
                          ? null
                          : CompanyDashboardPalette.surfaceMuted.withValues(
                              alpha: AppColors.isDark ? 0.66 : 0.78,
                            ),
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(
                        color: selected
                            ? Colors.white.withValues(alpha: 0.14)
                            : CompanyDashboardPalette.border,
                      ),
                      boxShadow: selected
                          ? [
                              BoxShadow(
                                color: CompanyDashboardPalette.primary
                                    .withValues(alpha: 0.18),
                                blurRadius: 18,
                                offset: const Offset(0, 8),
                              ),
                            ]
                          : null,
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          selected ? destination.activeIcon : destination.icon,
                          size: 18,
                          color: selected
                              ? Colors.white
                              : CompanyDashboardPalette.textSecondary,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          destination.label,
                          style: GoogleFonts.poppins(
                            fontSize: 12.2,
                            fontWeight: FontWeight.w600,
                            color: selected
                                ? Colors.white
                                : CompanyDashboardPalette.textPrimary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class CompanyPillNavigationBar extends StatelessWidget {
  final List<CompanyWorkspaceDestination> destinations;
  final int currentIndex;
  final ValueChanged<int> onTap;

  const CompanyPillNavigationBar({
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
    const idleFlex = 5;

    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
      child: AppNavScrollSwitcher(
        currentIndex: currentIndex,
        itemCount: destinations.length,
        onIndexChanged: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 5),
          decoration: BoxDecoration(
            color: AppColors.isDark
                ? CompanyDashboardPalette.surfaceElevated.withValues(
                    alpha: 0.96,
                  )
                : CompanyDashboardPalette.surface.withValues(alpha: 0.96),
            borderRadius: BorderRadius.circular(28),
            border: Border.all(
              color: CompanyDashboardPalette.border.withValues(alpha: 0.94),
            ),
            boxShadow: [
              BoxShadow(
                color: CompanyDashboardPalette.primary.withValues(
                  alpha: AppColors.isDark ? 0.16 : 0.11,
                ),
                blurRadius: 24,
                offset: const Offset(0, 12),
              ),
              BoxShadow(
                color: AppColors.current.shadow.withValues(
                  alpha: AppColors.isDark ? 0.24 : 0.06,
                ),
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
                  child: _CompanyPillNavItem(
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
      ),
    );
  }
}

class CompanyWorkspaceActionButton extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final VoidCallback? onTap;
  final int badgeCount;
  final Color? color;

  const CompanyWorkspaceActionButton({
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
        color: CompanyDashboardPalette.surfaceMuted,
        borderRadius: BorderRadius.circular(18),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(18),
          child: SizedBox(
            width: 48,
            height: 48,
            child: Stack(
              clipBehavior: Clip.none,
              alignment: Alignment.center,
              children: [
                Icon(
                  icon,
                  size: 21,
                  color: color ?? CompanyDashboardPalette.textPrimary,
                ),
                if (badgeCount > 0)
                  Positioned(
                    top: 8,
                    right: 8,
                    child: Container(
                      constraints: const BoxConstraints(
                        minWidth: 18,
                        minHeight: 18,
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 4,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: CompanyDashboardPalette.accent,
                        borderRadius: BorderRadius.circular(999),
                        border: Border.all(
                          color: CompanyDashboardPalette.surfaceMuted,
                          width: 1.4,
                        ),
                      ),
                      child: Text(
                        badgeCount > 9 ? '9+' : '$badgeCount',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.poppins(
                          fontSize: 9,
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

class _CompanyPillNavItem extends StatelessWidget {
  final CompanyWorkspaceDestination destination;
  final bool selected;
  final bool compact;
  final VoidCallback onTap;

  const _CompanyPillNavItem({
    required this.destination,
    required this.selected,
    required this.compact,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final selectedGradient = LinearGradient(
      colors: [
        CompanyDashboardPalette.primaryDark,
        CompanyDashboardPalette.primary,
        CompanyDashboardPalette.secondaryDark,
      ],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    );

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(22),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 280),
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
                  ? Colors.white.withValues(alpha: 0.20)
                  : Colors.transparent,
            ),
            boxShadow: selected
                ? [
                    BoxShadow(
                      color: CompanyDashboardPalette.primary.withValues(
                        alpha: 0.24,
                      ),
                      blurRadius: 16,
                      offset: const Offset(0, 8),
                    ),
                  ]
                : null,
          ),
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 260),
            switchInCurve: Curves.easeOutBack,
            switchOutCurve: Curves.easeInCubic,
            transitionBuilder: (child, animation) => ScaleTransition(
              scale: Tween<double>(begin: 0.72, end: 1.0).animate(animation),
              child: FadeTransition(opacity: animation, child: child),
            ),
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
                            destination.label,
                            maxLines: 1,
                            softWrap: false,
                            style: GoogleFonts.poppins(
                              fontSize: compact ? 8.6 : 9.8,
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
                      color: CompanyDashboardPalette.textMuted.withValues(
                        alpha: 0.92,
                      ),
                    ),
                  ),
          ),
        ),
      ),
    );
  }
}

class CompanyWorkspaceProfileButton extends StatelessWidget {
  final UserModel? user;
  final VoidCallback onTap;
  final double size;
  final double borderRadius;
  final double avatarRadius;
  final EdgeInsetsGeometry padding;

  const CompanyWorkspaceProfileButton({
    super.key,
    required this.user,
    required this.onTap,
    this.size = 48,
    this.borderRadius = 18,
    this.avatarRadius = 18,
    this.padding = const EdgeInsets.all(2),
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: AppLocalizations.of(context)!.uiCompanyProfile,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(borderRadius),
          child: Container(
            width: size,
            height: size,
            padding: padding,
            decoration: BoxDecoration(
              color: CompanyDashboardPalette.surfaceMuted,
              borderRadius: BorderRadius.circular(borderRadius),
              border: Border.all(color: CompanyDashboardPalette.border),
            ),
            child: Center(
              child: ProfileAvatar(user: user, radius: avatarRadius),
            ),
          ),
        ),
      ),
    );
  }
}

class _WorkspaceMetaPill extends StatelessWidget {
  final IconData icon;
  final String label;

  const _WorkspaceMetaPill({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: CompanyDashboardPalette.surfaceMuted,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: CompanyDashboardPalette.border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: CompanyDashboardPalette.primary),
          const SizedBox(width: 6),
          Text(
            label,
            style: GoogleFonts.poppins(
              fontSize: 11.5,
              fontWeight: FontWeight.w600,
              color: CompanyDashboardPalette.textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}
