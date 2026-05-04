import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../config/avatar_config.dart';
import '../l10n/generated/app_localizations.dart';
import '../models/user_model.dart';
import '../providers/subscription_provider.dart';
import '../services/premium_status_resolver.dart';
import '../services/public_profile_service.dart';
import '../theme/app_typography.dart';

/// Centralized widget that resolves and displays the correct profile image
/// for any user (student, company, admin).
///
/// Resolution order for students:
///   1. photoType == 'upload' && profileImage is non-empty -> network image
///   2. photoType == 'avatar' && avatarId is valid -> built-in avatar icon
///   3. profileImage is non-empty (legacy / Google) -> network image
///   4. fallback -> initials
///
/// Resolution order for companies:
///   1. photoType == 'upload' && logo is non-empty -> network image
///   2. logo is non-empty (legacy) -> network image
///   3. fallback -> business icon
class ProfileAvatar extends StatefulWidget {
  final UserModel? user;
  final double radius;

  /// Optional lookup when only the target user's ID is known.
  final String? userId;

  /// Optional overrides when a full [UserModel] is not available.
  final String? photoType;
  final String? avatarId;
  final String? photoUrl;
  final String? fallbackName;
  final String? role;
  final bool? isPremium;

  const ProfileAvatar({
    super.key,
    this.user,
    this.radius = 24,
    this.userId,
    this.photoType,
    this.avatarId,
    this.photoUrl,
    this.fallbackName,
    this.role,
    this.isPremium,
  });

  @override
  State<ProfileAvatar> createState() => _ProfileAvatarState();
}

class _ProfileAvatarState extends State<ProfileAvatar> {
  Future<UserModel?>? _profileLookup;

  @override
  void initState() {
    super.initState();
    _refreshLookup();
  }

  @override
  void didUpdateWidget(covariant ProfileAvatar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.user != oldWidget.user ||
        widget.userId != oldWidget.userId ||
        widget.photoType != oldWidget.photoType ||
        widget.avatarId != oldWidget.avatarId ||
        widget.photoUrl != oldWidget.photoUrl ||
        widget.role != oldWidget.role) {
      _refreshLookup();
    }
  }

  void _refreshLookup() {
    _profileLookup = _shouldLookupRemoteProfile()
        ? PublicProfileService.instance.fetchPublicProfile(widget.userId!)
        : null;
  }

  bool _shouldLookupRemoteProfile() {
    if (widget.user != null) {
      return false;
    }

    final normalizedUserId = (widget.userId ?? '').trim();
    if (normalizedUserId.isEmpty) {
      return false;
    }

    if ((widget.photoUrl ?? '').trim().isNotEmpty) {
      return false;
    }

    final resolvedRole = widget.role ?? 'student';
    if (resolvedRole != 'company' &&
        widget.photoType == 'avatar' &&
        AvatarConfig.getById(widget.avatarId) != null) {
      return false;
    }

    return true;
  }

  @override
  Widget build(BuildContext context) {
    if (_profileLookup == null) {
      return _buildResolvedAvatar(context, widget.user);
    }

    return FutureBuilder<UserModel?>(
      future: _profileLookup,
      builder: (context, snapshot) {
        return _buildResolvedAvatar(context, snapshot.data ?? widget.user);
      },
    );
  }

  Widget _buildResolvedAvatar(BuildContext context, UserModel? resolvedUser) {
    final resolvedRole = resolvedUser?.role ?? widget.role ?? 'student';
    final resolvedPhotoType = resolvedUser?.photoType ?? widget.photoType;
    final resolvedAvatarId = resolvedUser?.avatarId ?? widget.avatarId;
    final resolvedName =
        resolvedUser?.fullName ??
        resolvedUser?.companyName ??
        widget.fallbackName ??
        '';
    final resolvedPhotoUrl = _resolvePhotoUrl(
      resolvedRole,
      resolvedUser,
      widget.photoUrl,
    );

    late final Widget avatar;
    if (resolvedPhotoType == 'upload' && resolvedPhotoUrl.isNotEmpty) {
      avatar = _buildNetworkAvatar(
        resolvedPhotoUrl,
        resolvedName,
        resolvedRole,
      );
    } else if (resolvedRole != 'company' && resolvedPhotoType == 'avatar') {
      final avatarDefinition = AvatarConfig.getById(resolvedAvatarId);
      if (avatarDefinition != null) {
        return _withPremiumTreatment(
          context,
          CircleAvatar(
            radius: widget.radius,
            backgroundColor: avatarDefinition.backgroundColor,
            child: Icon(
              avatarDefinition.icon,
              color: avatarDefinition.iconColor,
              size: widget.radius,
            ),
          ),
          resolvedUser,
          resolvedRole,
        );
      }
      avatar = _buildFallback(resolvedName, resolvedRole);
    } else if (resolvedPhotoUrl.isNotEmpty) {
      avatar = _buildNetworkAvatar(
        resolvedPhotoUrl,
        resolvedName,
        resolvedRole,
      );
    } else {
      avatar = _buildFallback(resolvedName, resolvedRole);
    }

    return _withPremiumTreatment(context, avatar, resolvedUser, resolvedRole);
  }

  Widget _withPremiumTreatment(
    BuildContext context,
    Widget avatar,
    UserModel? resolvedUser,
    String resolvedRole,
  ) {
    if (resolvedRole != 'student') {
      return avatar;
    }

    final resolvedUserId = (resolvedUser?.uid ?? widget.userId ?? '').trim();
    final explicitPremium =
        widget.isPremium ??
        resolvedUser?.hasActivePremium ??
        _currentUserPremiumStatus(context, resolvedUserId);

    if (explicitPremium != null) {
      if (resolvedUserId.isNotEmpty) {
        PremiumStatusResolver.instance.prime(resolvedUserId, explicitPremium);
      }
      return explicitPremium
          ? _PremiumAvatarFrame(radius: widget.radius, child: avatar)
          : avatar;
    }

    if (resolvedUserId.isEmpty) {
      return avatar;
    }

    final cachedPremium = PremiumStatusResolver.instance.cachedActivePremium(
      resolvedUserId,
    );
    if (cachedPremium != null) {
      return cachedPremium
          ? _PremiumAvatarFrame(radius: widget.radius, child: avatar)
          : avatar;
    }

    return FutureBuilder<bool>(
      future: PremiumStatusResolver.instance.hasActivePremiumForStudent(
        resolvedUserId,
      ),
      builder: (context, snapshot) {
        return snapshot.data == true
            ? _PremiumAvatarFrame(radius: widget.radius, child: avatar)
            : avatar;
      },
    );
  }

  bool? _currentUserPremiumStatus(BuildContext context, String userId) {
    if (userId.isEmpty) {
      return null;
    }

    try {
      final subscriptionProvider = context.watch<SubscriptionProvider>();
      return subscriptionProvider.subscription?.uid.trim() == userId
          ? subscriptionProvider.hasActivePremium
          : null;
    } on ProviderNotFoundException {
      return null;
    }
  }

  String _resolvePhotoUrl(
    String resolvedRole,
    UserModel? resolvedUser,
    String? overridePhotoUrl,
  ) {
    if (overridePhotoUrl != null && overridePhotoUrl.trim().isNotEmpty) {
      return overridePhotoUrl.trim();
    }

    if (resolvedUser == null) {
      return '';
    }

    if (resolvedRole == 'company') {
      final logo = (resolvedUser.logo ?? '').trim();
      if (logo.isNotEmpty) {
        return logo;
      }

      return resolvedUser.profileImage.trim();
    }

    final profileImage = resolvedUser.profileImage.trim();
    if (profileImage.isNotEmpty) {
      return profileImage;
    }

    return (resolvedUser.logo ?? '').trim();
  }

  Widget _buildNetworkAvatar(String url, String name, String role) {
    if (role == 'company') {
      final diameter = widget.radius * 2;

      return Container(
        width: diameter,
        height: diameter,
        padding: EdgeInsets.all(widget.radius * 0.16),
        decoration: BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
          border: Border.all(color: const Color(0xFFE2E8F0)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: CachedNetworkImage(
          imageUrl: url,
          fit: BoxFit.contain,
          placeholder: (context, url) => Center(
            child: SizedBox(
              width: widget.radius,
              height: widget.radius,
              child: const CircularProgressIndicator(strokeWidth: 2),
            ),
          ),
          errorWidget: (context, url, error) => Icon(
            Icons.business_center_outlined,
            color: _fallbackColor(role),
            size: widget.radius,
          ),
        ),
      );
    }

    return CachedNetworkImage(
      imageUrl: url,
      imageBuilder: (context, imageProvider) =>
          CircleAvatar(radius: widget.radius, backgroundImage: imageProvider),
      placeholder: (context, url) => CircleAvatar(
        radius: widget.radius,
        backgroundColor: _fallbackColor(role),
        child: SizedBox(
          width: widget.radius,
          height: widget.radius,
          child: const CircularProgressIndicator(strokeWidth: 2),
        ),
      ),
      errorWidget: (context, url, error) => _buildFallback(name, role),
    );
  }

  Widget _buildFallback(String name, String role) {
    if (role == 'company') {
      final diameter = widget.radius * 2;
      return Container(
        width: diameter,
        height: diameter,
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF0F4C81), Color(0xFF0EA5E9)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white.withValues(alpha: 0.72)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        alignment: Alignment.center,
        child: Padding(
          padding: EdgeInsets.all(widget.radius * 0.20),
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              _fallbackInitials(name, role),
              maxLines: 1,
              style: AppTypography.product(
                fontSize: widget.radius * 0.9,
                height: 1,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
          ),
        ),
      );
    }

    final initial = _fallbackInitial(name, role);
    final diameter = widget.radius * 2;

    return Container(
      width: diameter,
      height: diameter,
      decoration: BoxDecoration(
        color: _fallbackColor(role),
        shape: BoxShape.circle,
      ),
      alignment: Alignment.center,
      child: Padding(
        padding: EdgeInsets.all(widget.radius * 0.28),
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            initial,
            textAlign: TextAlign.center,
            maxLines: 1,
            style: AppTypography.product(
              fontSize: widget.radius,
              height: 1,
              fontWeight: FontWeight.w700,
              color: _fallbackTextColor(role),
            ),
          ),
        ),
      ),
    );
  }

  String _fallbackInitial(String name, String role) {
    final trimmed = name.trim();
    if (trimmed.isNotEmpty) {
      return trimmed.substring(0, 1).toUpperCase();
    }

    return role == 'admin' ? 'A' : '?';
  }

  String _fallbackInitials(String name, String role) {
    final trimmed = name.trim();
    if (trimmed.isEmpty) {
      return role == 'admin' ? 'AD' : 'CO';
    }

    final parts = trimmed
        .split(RegExp(r'\s+'))
        .where((part) => part.trim().isNotEmpty)
        .toList(growable: false);
    if (parts.length == 1) {
      return parts.first.substring(0, 1).toUpperCase();
    }

    return '${parts.first.substring(0, 1)}${parts.last.substring(0, 1)}'
        .toUpperCase();
  }

  Color _fallbackColor(String role) {
    switch (role) {
      case 'company':
        return const Color(0xFF004E98);
      case 'admin':
        return const Color(0xFFFF8C00);
      default:
        return const Color(0xFF4F46E5);
    }
  }

  Color _fallbackTextColor(String role) {
    switch (role) {
      case 'company':
        return Colors.white;
      case 'admin':
        return Colors.white;
      default:
        return Colors.white;
    }
  }
}

class _PremiumAvatarFrame extends StatelessWidget {
  final double radius;
  final Widget child;

  const _PremiumAvatarFrame({required this.radius, required this.child});

  @override
  Widget build(BuildContext context) {
    final diameter = radius * 2;
    final strokeWidth = (radius * 0.10).clamp(1.5, 3.2).toDouble();
    final badgeSize = (radius * 0.62).clamp(11.0, 23.0).toDouble();
    final iconSize = (badgeSize * 0.62).clamp(7.0, 15.0).toDouble();
    final label = AppLocalizations.of(context)?.premiumBadgeLabel ?? 'Premium';

    return Tooltip(
      message: label,
      child: Semantics(
        label: label,
        child: SizedBox(
          width: diameter,
          height: diameter,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Positioned.fill(child: child),
              Positioned.fill(
                child: IgnorePointer(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: const Color(0xFFF6C453),
                        width: strokeWidth,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(
                            0xFFF6C453,
                          ).withValues(alpha: 0.22),
                          blurRadius: radius * 0.38,
                          spreadRadius: 0.5,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              Positioned(
                right: 0,
                bottom: 0,
                child: Container(
                  width: badgeSize,
                  height: badgeSize,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFFFFD76A), Color(0xFFE59A18)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.92),
                      width: (badgeSize * 0.12).clamp(1.2, 2.0).toDouble(),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFFE59A18).withValues(alpha: 0.34),
                        blurRadius: radius * 0.22,
                        offset: const Offset(0, 1),
                      ),
                    ],
                  ),
                  alignment: Alignment.center,
                  child: Icon(
                    Icons.workspace_premium_rounded,
                    size: iconSize,
                    color: const Color(0xFF3B2500),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
