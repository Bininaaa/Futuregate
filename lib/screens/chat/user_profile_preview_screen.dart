import 'package:flutter/material.dart';

import '../../l10n/generated/app_localizations.dart';
import '../../models/user_model.dart';
import '../../services/public_profile_service.dart';
import '../../utils/admin_identity.dart';
import '../../utils/display_text.dart';
import '../../utils/localized_display.dart';
import '../../widgets/chat/chat_formatters.dart';
import '../../widgets/chat/chat_theme.dart';
import '../../widgets/profile_avatar.dart';

enum UserProfilePreviewPresentation { floatingDialog, bottomSheet }

Future<void> showFloatingUserProfilePreview(
  BuildContext context, {
  required String userId,
  String fallbackName = '',
  String fallbackRole = '',
  String fallbackHeadline = '',
  String fallbackAbout = '',
  String fallbackLocation = '',
  String fallbackWebsite = '',
  String contextLabel = '',
  bool showRole = true,
  UserProfilePreviewPresentation presentation =
      UserProfilePreviewPresentation.floatingDialog,
}) {
  if (presentation == UserProfilePreviewPresentation.bottomSheet) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        return DraggableScrollableSheet(
          initialChildSize: 0.68,
          minChildSize: 0.42,
          maxChildSize: 0.90,
          expand: false,
          builder: (context, scrollController) {
            return UserProfilePreviewScreen(
              userId: userId,
              fallbackName: fallbackName,
              fallbackRole: fallbackRole,
              fallbackHeadline: fallbackHeadline,
              fallbackAbout: fallbackAbout,
              fallbackLocation: fallbackLocation,
              fallbackWebsite: fallbackWebsite,
              contextLabel: contextLabel,
              showRole: showRole,
              scrollController: scrollController,
              asSheet: true,
            );
          },
        );
      },
    );
  }

  final size = MediaQuery.sizeOf(context);
  final isCompact = size.width < 520;
  final horizontalInset = isCompact ? 10.0 : 24.0;
  final topInset = MediaQuery.viewPaddingOf(context).top + 16;
  final bottomInset = MediaQuery.viewPaddingOf(context).bottom + 10;

  return showDialog<void>(
    context: context,
    barrierColor: Colors.black.withValues(alpha: 0.30),
    useSafeArea: false,
    builder: (dialogContext) {
      final dialogSize = MediaQuery.sizeOf(dialogContext);
      final viewInsets = MediaQuery.viewInsetsOf(dialogContext);
      final maxHeight = dialogSize.height * (isCompact ? 0.78 : 0.74);

      return Align(
        alignment: isCompact ? Alignment.bottomCenter : Alignment.center,
        child: AnimatedPadding(
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOutCubic,
          padding: EdgeInsets.fromLTRB(
            horizontalInset,
            topInset,
            horizontalInset,
            bottomInset + viewInsets.bottom,
          ),
          child: Material(
            color: Colors.transparent,
            child: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: 460, maxHeight: maxHeight),
              child: UserProfilePreviewScreen(
                userId: userId,
                fallbackName: fallbackName,
                fallbackRole: fallbackRole,
                fallbackHeadline: fallbackHeadline,
                fallbackAbout: fallbackAbout,
                fallbackLocation: fallbackLocation,
                fallbackWebsite: fallbackWebsite,
                contextLabel: contextLabel,
                showRole: showRole,
              ),
            ),
          ),
        ),
      );
    },
  );
}

class UserProfilePreviewScreen extends StatefulWidget {
  final String userId;
  final String fallbackName;
  final String fallbackRole;
  final String fallbackHeadline;
  final String fallbackAbout;
  final String fallbackLocation;
  final String fallbackWebsite;
  final String contextLabel;
  final bool showRole;
  final ScrollController? scrollController;
  final bool asSheet;

  const UserProfilePreviewScreen({
    super.key,
    required this.userId,
    this.fallbackName = '',
    this.fallbackRole = '',
    this.fallbackHeadline = '',
    this.fallbackAbout = '',
    this.fallbackLocation = '',
    this.fallbackWebsite = '',
    this.contextLabel = '',
    this.showRole = true,
    this.scrollController,
    this.asSheet = false,
  });

  @override
  State<UserProfilePreviewScreen> createState() =>
      _UserProfilePreviewScreenState();
}

class _UserProfilePreviewScreenState extends State<UserProfilePreviewScreen> {
  late Future<UserModel?> _profileFuture;

  @override
  void initState() {
    super.initState();
    _profileFuture = PublicProfileService.instance.fetchPublicProfile(
      widget.userId,
    );
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<UserModel?>(
      future: _profileFuture,
      builder: (context, snapshot) {
        final l10n = AppLocalizations.of(context)!;
        final user = snapshot.data;
        final details = _buildDetails(user);
        final about = _about(user);
        final title = _profileTitle(user);

        return Container(
          decoration: BoxDecoration(
            color: ChatThemePalette.background,
            borderRadius: widget.asSheet
                ? const BorderRadius.vertical(top: Radius.circular(28))
                : BorderRadius.circular(28),
            border: Border.all(
              color: ChatThemePalette.border.withValues(alpha: 0.9),
            ),
            boxShadow: ChatThemeStyles.softShadow(0.22),
          ),
          clipBehavior: Clip.antiAlias,
          child: SingleChildScrollView(
            controller: widget.scrollController,
            padding: const EdgeInsets.fromLTRB(14, 10, 14, 18),
            physics: const BouncingScrollPhysics(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisSize: MainAxisSize.min,
              children: [
                _FloatingHeader(
                  title: title,
                  onClose: () => Navigator.maybePop(context),
                ),
                const SizedBox(height: 10),
                _ProfileIdentityBlock(
                  user: user,
                  userId: widget.userId,
                  name: _displayName(user),
                  roleLabel: _roleLabel(user),
                  headline: _headline(user),
                  fallbackName: widget.fallbackName,
                  fallbackRole: widget.fallbackRole,
                  contextLabel: widget.contextLabel,
                  showRole: widget.showRole,
                ),
                if (snapshot.hasError) ...[
                  const SizedBox(height: 12),
                  _InlineNotice(
                    icon: Icons.sync_problem_outlined,
                    title: l10n.uiProfileSync,
                    message: LocalizedDisplay.isArabic(context)
                        ? 'تعذّر تحديث تفاصيل الملف المباشرة، لذلك تظهر المعلومات الاحتياطية.'
                        : LocalizedDisplay.isFrench(context)
                        ? 'Les détails du profil n’ont pas pu être actualisés, les informations de secours sont donc affichées.'
                        : 'Live profile details could not be refreshed, so fallback information is shown.',
                  ),
                ],
                if (about.isNotEmpty) ...[
                  const SizedBox(height: 14),
                  _FloatingSection(
                    title: l10n.uiAbout,
                    icon: Icons.notes_rounded,
                    child: _TextPanel(
                      text: DisplayText.capitalizeDisplayValue(about),
                    ),
                  ),
                ],
                const SizedBox(height: 14),
                _FloatingSection(
                  title: l10n.uiDetails,
                  icon: Icons.badge_outlined,
                  child: Column(
                    children: [
                      for (var index = 0; index < details.length; index++) ...[
                        if (index > 0) const SizedBox(height: 10),
                        _DetailRow(item: details[index]),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  List<_ProfileDetailItem> _buildDetails(UserModel? user) {
    final l10n = AppLocalizations.of(context)!;
    final role = _resolvedRole(user);
    final items = <_ProfileDetailItem>[];
    if (widget.showRole) {
      items.add(
        _ProfileDetailItem(
          title: l10n.uiRole,
          value: _roleLabel(user),
          icon: Icons.verified_user_outlined,
          preserveCase: true,
        ),
      );
    }

    if (role == 'admin') {
      return items;
    }

    final email = (user?.email ?? '').trim();
    if (email.isNotEmpty) {
      items.add(
        _ProfileDetailItem(
          title: l10n.uiEmail,
          value: email,
          icon: Icons.email_outlined,
          preserveCase: true,
        ),
      );
    }

    final phone = (user?.phone ?? '').trim();
    if (phone.isNotEmpty) {
      items.add(
        _ProfileDetailItem(
          title: l10n.uiPhone,
          value: phone,
          icon: Icons.phone_outlined,
          preserveCase: true,
        ),
      );
    }

    if (role == 'company') {
      final sector = (user?.sector ?? '').trim().isNotEmpty
          ? (user?.sector ?? '').trim()
          : widget.fallbackHeadline.trim();
      if (sector.isNotEmpty) {
        items.add(
          _ProfileDetailItem(
            title: l10n.uiSector,
            value: sector,
            icon: Icons.business_center_outlined,
          ),
        );
      }
    } else {
      final academicLevel = (user?.academicLevel ?? '').trim();
      if (academicLevel.isNotEmpty) {
        items.add(
          _ProfileDetailItem(
            title: l10n.uiAcademicLevel,
            value: academicLevel,
            icon: Icons.school_outlined,
          ),
        );
      }

      final university = (user?.university ?? '').trim();
      if (university.isNotEmpty) {
        items.add(
          _ProfileDetailItem(
            title: l10n.uiUniversity,
            value: university,
            icon: Icons.apartment_outlined,
          ),
        );
      }

      final fieldOfStudy = (user?.fieldOfStudy ?? '').trim();
      if (fieldOfStudy.isNotEmpty) {
        items.add(
          _ProfileDetailItem(
            title: l10n.uiFieldOfStudy,
            value: fieldOfStudy,
            icon: Icons.menu_book_outlined,
          ),
        );
      }
    }

    final location = (user?.location ?? '').trim().isNotEmpty
        ? (user?.location ?? '').trim()
        : widget.fallbackLocation.trim();
    if (location.isNotEmpty) {
      items.add(
        _ProfileDetailItem(
          title: l10n.uiLocation,
          value: location,
          icon: Icons.location_on_outlined,
        ),
      );
    }

    final website = (user?.website ?? '').trim().isNotEmpty
        ? (user?.website ?? '').trim()
        : widget.fallbackWebsite.trim();
    if (website.isNotEmpty) {
      items.add(
        _ProfileDetailItem(
          title: l10n.uiWebsite,
          value: website,
          icon: Icons.language_outlined,
          preserveCase: true,
        ),
      );
    }

    return items;
  }

  String _profileTitle(UserModel? user) {
    final l10n = AppLocalizations.of(context)!;
    return _resolvedRole(user) == 'company'
        ? l10n.uiCompanyProfile
        : l10n.uiProfile;
  }

  String _displayName(UserModel? user) {
    if (_resolvedRole(user) == 'admin') {
      return AdminIdentity.publicName;
    }

    final companyName = (user?.companyName ?? '').trim();
    if (companyName.isNotEmpty) {
      return companyName;
    }

    final fullName = (user?.fullName ?? '').trim();
    if (fullName.isNotEmpty) {
      return fullName;
    }

    if (widget.fallbackName.trim().isNotEmpty) {
      return widget.fallbackName.trim();
    }

    return LocalizedDisplay.isArabic(context)
        ? 'جهة اتصال'
        : LocalizedDisplay.isFrench(context)
        ? 'Contact'
        : 'Chat Contact';
  }

  String _headline(UserModel? user) {
    final role = _resolvedRole(user);
    if (role == 'admin') {
      return '';
    }

    if (role == 'company') {
      final sector = (user?.sector ?? '').trim();
      if (sector.isNotEmpty) {
        return sector;
      }

      return widget.fallbackHeadline.trim();
    }

    final university = (user?.university ?? '').trim();
    final field = (user?.fieldOfStudy ?? '').trim();
    if (university.isNotEmpty && field.isNotEmpty) {
      return '$field - $university';
    }

    if (field.isNotEmpty) {
      return field;
    }

    if (university.isNotEmpty) {
      return university;
    }

    return widget.fallbackHeadline.trim();
  }

  String _about(UserModel? user) {
    final role = _resolvedRole(user);
    if (role == 'admin') {
      return (user?.bio ?? '').trim();
    }

    if (role == 'company') {
      final description = (user?.description ?? '').trim();
      if (description.isNotEmpty) {
        return description;
      }
    } else {
      final bio = (user?.bio ?? '').trim();
      if (bio.isNotEmpty) {
        return bio;
      }
    }

    return widget.fallbackAbout.trim();
  }

  String _roleLabel(UserModel? user) {
    final l10n = AppLocalizations.of(context)!;
    switch (_resolvedRole(user)) {
      case 'company':
        return l10n.uiCompany.toUpperCase();
      case 'student':
        return l10n.uiStudent.toUpperCase();
      case 'admin':
        return l10n.uiAdmins.toUpperCase();
      default:
        return l10n.uiUsers.toUpperCase();
    }
  }

  String _resolvedRole(UserModel? user) {
    return (user?.role ?? widget.fallbackRole).trim().toLowerCase();
  }
}

class _ProfileDetailItem {
  final String title;
  final String value;
  final IconData icon;
  final bool preserveCase;

  const _ProfileDetailItem({
    required this.title,
    required this.value,
    required this.icon,
    this.preserveCase = false,
  });
}

class _FloatingHeader extends StatelessWidget {
  final String title;
  final VoidCallback onClose;

  const _FloatingHeader({required this.title, required this.onClose});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Center(
          child: Container(
            width: 42,
            height: 4,
            decoration: BoxDecoration(
              color: ChatThemePalette.border,
              borderRadius: BorderRadius.circular(999),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: Text(
                title,
                style: ChatThemeStyles.cardTitle().copyWith(fontSize: 18),
              ),
            ),
            _ToolbarButton(
              icon: Icons.close_rounded,
              tooltip: MaterialLocalizations.of(context).closeButtonTooltip,
              onTap: onClose,
            ),
          ],
        ),
      ],
    );
  }
}

class _ProfileIdentityBlock extends StatelessWidget {
  final UserModel? user;
  final String userId;
  final String name;
  final String roleLabel;
  final String headline;
  final String fallbackName;
  final String fallbackRole;
  final String contextLabel;
  final bool showRole;

  const _ProfileIdentityBlock({
    required this.user,
    required this.userId,
    required this.name,
    required this.roleLabel,
    required this.headline,
    required this.fallbackName,
    required this.fallbackRole,
    required this.contextLabel,
    required this.showRole,
  });

  @override
  Widget build(BuildContext context) {
    final presence = ChatFormatters.presenceLabel(
      user?.lastSeenAt,
      isOnline: user?.isOnline ?? false,
      context: context,
    );
    final resolvedHeadline = headline.trim();
    final resolvedContext = contextLabel.trim();

    return Container(
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 20),
      decoration: BoxDecoration(
        gradient: ChatThemePalette.fabGradient,
        borderRadius: BorderRadius.circular(22),
        boxShadow: ChatThemeStyles.softShadow(0.18),
      ),
      child: Column(
        children: [
          ProfileAvatar(
            user: user,
            userId: userId,
            radius: 42,
            fallbackName: fallbackName,
            role: fallbackRole,
          ),
          const SizedBox(height: 14),
          Text(
            DisplayText.capitalizeDisplayValue(name),
            textAlign: TextAlign.center,
            style: ChatThemeStyles.title(Colors.white).copyWith(fontSize: 24),
          ),
          if (resolvedHeadline.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(
              DisplayText.capitalizeDisplayValue(resolvedHeadline),
              textAlign: TextAlign.center,
              style: ChatThemeStyles.body(Colors.white.withValues(alpha: 0.82)),
            ),
          ],
          const SizedBox(height: 12),
          Wrap(
            alignment: WrapAlignment.center,
            spacing: 8,
            runSpacing: 8,
            children: [
              if (showRole) _RolePill(label: roleLabel),
              _PresencePill(label: presence, isOnline: user?.isOnline ?? false),
              if (resolvedContext.isNotEmpty)
                _ContextPill(label: resolvedContext),
            ],
          ),
        ],
      ),
    );
  }
}

class _RolePill extends StatelessWidget {
  final String label;

  const _RolePill({required this.label});

  @override
  Widget build(BuildContext context) {
    return _HeroPill(icon: Icons.verified_outlined, label: label);
  }
}

class _PresencePill extends StatelessWidget {
  final String label;
  final bool isOnline;

  const _PresencePill({required this.label, required this.isOnline});

  @override
  Widget build(BuildContext context) {
    return _HeroPill(
      icon: isOnline ? Icons.circle : Icons.schedule_rounded,
      label: label,
      iconColor: isOnline ? ChatThemePalette.success : Colors.white,
    );
  }
}

class _ContextPill extends StatelessWidget {
  final String label;

  const _ContextPill({required this.label});

  @override
  Widget build(BuildContext context) {
    return _HeroPill(icon: Icons.label_outline_rounded, label: label);
  }
}

class _HeroPill extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color? iconColor;

  const _HeroPill({required this.icon, required this.label, this.iconColor});

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(maxWidth: 220),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Colors.white.withValues(alpha: 0.20)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: iconColor ?? Colors.white),
          const SizedBox(width: 5),
          Flexible(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: ChatThemeStyles.meta(
                Colors.white.withValues(alpha: 0.94),
              ).copyWith(fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }
}

class _FloatingSection extends StatelessWidget {
  final String title;
  final IconData icon;
  final Widget child;

  const _FloatingSection({
    required this.title,
    required this.icon,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 2),
          child: Row(
            children: [
              Icon(icon, size: 15, color: ChatThemePalette.primary),
              const SizedBox(width: 6),
              Text(
                title,
                style: ChatThemeStyles.sectionLabel(
                  ChatThemePalette.primary,
                ).copyWith(fontSize: 12),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        child,
      ],
    );
  }
}

class _TextPanel extends StatelessWidget {
  final String text;

  const _TextPanel({required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: ChatThemePalette.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: ChatThemePalette.border),
      ),
      child: Text(
        text,
        style: ChatThemeStyles.body(ChatThemePalette.textSecondary),
      ),
    );
  }
}

class _InlineNotice extends StatelessWidget {
  final IconData icon;
  final String title;
  final String message;

  const _InlineNotice({
    required this.icon,
    required this.title,
    required this.message,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: ChatThemePalette.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: ChatThemePalette.border),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: ChatThemePalette.primary, size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: ChatThemeStyles.cardTitle()),
                const SizedBox(height: 4),
                Text(
                  message,
                  style: ChatThemeStyles.body(ChatThemePalette.textSecondary),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final _ProfileDetailItem item;

  const _DetailRow({required this.item});

  @override
  Widget build(BuildContext context) {
    final displayValue = item.preserveCase
        ? item.value
        : DisplayText.capitalizeDisplayValue(item.value);

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: ChatThemePalette.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: ChatThemePalette.border),
      ),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: ChatThemePalette.primary.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(13),
            ),
            child: Icon(item.icon, color: ChatThemePalette.primary, size: 19),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(item.title, style: ChatThemeStyles.meta()),
                const SizedBox(height: 4),
                Text(
                  displayValue,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  style: ChatThemeStyles.cardTitle().copyWith(fontSize: 14),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ToolbarButton extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final VoidCallback? onTap;

  const _ToolbarButton({required this.icon, required this.tooltip, this.onTap});

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Ink(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: ChatThemePalette.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: ChatThemePalette.border),
            ),
            child: Icon(icon, color: ChatThemePalette.textPrimary, size: 20),
          ),
        ),
      ),
    );
  }
}
