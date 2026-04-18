import 'package:flutter/material.dart';
import '../../l10n/generated/app_localizations.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../models/user_model.dart';
import '../../theme/app_colors.dart';
import '../../utils/company_dashboard_palette.dart';
import '../profile_avatar.dart';

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

  const CompanyWorkspaceHeaderCard({
    super.key,
    required this.destination,
    required this.user,
    required this.unreadCount,
    required this.onNotificationsTap,
    required this.onProfileTap,
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
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [
                      Color(0xFF0E7490),
                      Color(0xFF0891B2),
                      Color(0xFF2563EB),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: CompanyDashboardPalette.primary.withValues(
                        alpha: 0.24,
                      ),
                      blurRadius: 18,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: Icon(
                  destination.activeIcon,
                  color: Colors.white,
                  size: 24,
                ),
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
                  const SizedBox(width: 8),
                  CompanyWorkspaceProfileButton(
                    user: user,
                    onTap: onProfileTap,
                  ),
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

class CompanyWorkspaceProfileButton extends StatelessWidget {
  final UserModel? user;
  final VoidCallback onTap;

  const CompanyWorkspaceProfileButton({
    super.key,
    required this.user,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: AppLocalizations.of(context)!.uiCompanyProfile,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(18),
          child: Container(
            width: 48,
            height: 48,
            padding: const EdgeInsets.all(2),
            decoration: BoxDecoration(
              color: CompanyDashboardPalette.surfaceMuted,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: CompanyDashboardPalette.border),
            ),
            child: Center(child: ProfileAvatar(user: user, radius: 18)),
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
