import 'package:flutter/material.dart';

import '../../models/user_model.dart';
import '../../services/public_profile_service.dart';
import '../../widgets/chat/chat_formatters.dart';
import '../../widgets/chat/chat_theme.dart';
import '../../widgets/profile_avatar.dart';

class UserProfilePreviewScreen extends StatefulWidget {
  final String userId;
  final String fallbackName;
  final String fallbackRole;
  final String fallbackHeadline;
  final String fallbackAbout;
  final String fallbackLocation;
  final String fallbackWebsite;
  final String contextLabel;

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
    return Scaffold(
      backgroundColor: ChatThemePalette.background,
      body: SafeArea(
        child: FutureBuilder<UserModel?>(
          future: _profileFuture,
          builder: (context, snapshot) {
            final user = snapshot.data;
            final about = _about(user);
            final headline = _headline(user);
            final title = _profileTitle(user);

            return ListView(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
              children: [
                Row(
                  children: [
                    _ToolbarButton(
                      icon: Icons.arrow_back_ios_new_rounded,
                      onTap: () => Navigator.pop(context),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Text(
                        title,
                        style: ChatThemeStyles.cardTitle().copyWith(
                          fontSize: 18,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Container(
                  padding: const EdgeInsets.all(22),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        ChatThemePalette.primary.withValues(alpha: 0.12),
                        ChatThemePalette.surface,
                        ChatThemePalette.surface,
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(30),
                    border: Border.all(color: ChatThemePalette.border),
                    boxShadow: ChatThemeStyles.softShadow(0.05),
                  ),
                  child: Column(
                    children: [
                      ProfileAvatar(
                        user: user,
                        userId: widget.userId,
                        radius: 42,
                        fallbackName: widget.fallbackName,
                        role: widget.fallbackRole,
                      ),
                      const SizedBox(height: 14),
                      Text(
                        _displayName(user),
                        textAlign: TextAlign.center,
                        style: ChatThemeStyles.title().copyWith(fontSize: 25),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 7,
                        ),
                        decoration: BoxDecoration(
                          color: _roleColor(user).withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Text(
                          _roleLabel(user),
                          style: ChatThemeStyles.meta(
                            _roleColor(user),
                          ).copyWith(fontWeight: FontWeight.w700),
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        ChatFormatters.presenceLabel(
                          user?.lastSeenAt,
                          isOnline: user?.isOnline ?? false,
                        ),
                        style: ChatThemeStyles.meta(
                          (user?.isOnline ?? false)
                              ? ChatThemePalette.success
                              : ChatThemePalette.textSecondary,
                        ).copyWith(fontWeight: FontWeight.w700),
                      ),
                      if (headline.isNotEmpty) ...[
                        const SizedBox(height: 14),
                        Text(
                          headline,
                          textAlign: TextAlign.center,
                          style: ChatThemeStyles.body(
                            ChatThemePalette.textSecondary,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                if (snapshot.hasError) ...[
                  const SizedBox(height: 12),
                  _InfoCard(
                    title: 'Profile Sync',
                    icon: Icons.sync_problem_outlined,
                    child: Text(
                      'Live profile details could not be refreshed, so you are seeing safe fallback information.',
                      style: ChatThemeStyles.body(
                        ChatThemePalette.textSecondary,
                      ),
                    ),
                  ),
                ],
                if (about.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  _InfoCard(
                    title: 'About',
                    icon: Icons.notes_rounded,
                    child: Text(
                      about,
                      style: ChatThemeStyles.body(
                        ChatThemePalette.textSecondary,
                      ),
                    ),
                  ),
                ],
                const SizedBox(height: 12),
                ..._buildDetails(user),
              ],
            );
          },
        ),
      ),
    );
  }

  List<Widget> _buildDetails(UserModel? user) {
    final items = <Widget>[];

    void addItem({
      required String title,
      required String value,
      required IconData icon,
    }) {
      if (value.trim().isEmpty) {
        return;
      }

      if (items.isNotEmpty) {
        items.add(const SizedBox(height: 12));
      }

      items.add(
        _InfoCard(
          title: title,
          icon: icon,
          child: Text(
            value,
            style: ChatThemeStyles.cardTitle().copyWith(fontSize: 14),
          ),
        ),
      );
    }

    addItem(
      title: 'Role',
      value: _roleLabel(user),
      icon: Icons.verified_user_outlined,
    );
    addItem(
      title: user?.role == 'company' ? 'Sector' : 'Academic Level',
      value: user?.role == 'company'
          ? (user?.sector ?? '').trim().isNotEmpty
                ? (user?.sector ?? '').trim()
                : widget.fallbackHeadline.trim()
          : (user?.academicLevel ?? '').trim(),
      icon: user?.role == 'company'
          ? Icons.business_center_outlined
          : Icons.school_outlined,
    );
    addItem(
      title: 'University',
      value: (user?.university ?? '').trim(),
      icon: Icons.apartment_outlined,
    );
    addItem(
      title: 'Field Of Study',
      value: (user?.fieldOfStudy ?? '').trim(),
      icon: Icons.menu_book_outlined,
    );
    addItem(
      title: 'Location',
      value: (user?.location ?? '').trim().isNotEmpty
          ? (user?.location ?? '').trim()
          : widget.fallbackLocation.trim(),
      icon: Icons.location_on_outlined,
    );
    addItem(
      title: 'Website',
      value: (user?.website ?? '').trim().isNotEmpty
          ? (user?.website ?? '').trim()
          : widget.fallbackWebsite.trim(),
      icon: Icons.language_outlined,
    );
    addItem(
      title: 'Conversation Context',
      value: widget.contextLabel.trim(),
      icon: Icons.forum_outlined,
    );

    if (items.isEmpty) {
      items.add(
        _InfoCard(
          title: 'Profile',
          icon: Icons.person_outline_rounded,
          child: Text(
            user?.role == 'company'
                ? 'This company has not published additional public details yet.'
                : 'This user has not shared additional public profile details yet.',
            style: ChatThemeStyles.body(ChatThemePalette.textSecondary),
          ),
        ),
      );
    }

    return items;
  }

  String _profileTitle(UserModel? user) {
    return _resolvedRole(user) == 'company' ? 'Company Profile' : 'Profile';
  }

  String _displayName(UserModel? user) {
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

    return 'Chat Contact';
  }

  String _headline(UserModel? user) {
    if (_resolvedRole(user) == 'company') {
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
    if (_resolvedRole(user) == 'company') {
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
    switch (_resolvedRole(user)) {
      case 'company':
        return 'COMPANY';
      case 'student':
        return 'STUDENT';
      case 'admin':
        return 'ADMIN';
      default:
        return 'USER';
    }
  }

  String _resolvedRole(UserModel? user) {
    return (user?.role ?? widget.fallbackRole).trim().toLowerCase();
  }

  Color _roleColor(UserModel? user) {
    return _resolvedRole(user) == 'company'
        ? ChatThemePalette.secondary
        : ChatThemePalette.primary;
  }
}

class _InfoCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final Widget child;

  const _InfoCard({
    required this.title,
    required this.icon,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: ChatThemePalette.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: ChatThemePalette.border),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: ChatThemePalette.primary.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: ChatThemePalette.primary, size: 20),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: ChatThemeStyles.meta()),
                const SizedBox(height: 4),
                child,
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
  final VoidCallback? onTap;

  const _ToolbarButton({required this.icon, this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
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
          child: Icon(icon, color: ChatThemePalette.textPrimary, size: 18),
        ),
      ),
    );
  }
}
