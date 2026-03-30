import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../config/avatar_config.dart';
import '../models/user_model.dart';
import '../services/public_profile_service.dart';

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
      return _buildResolvedAvatar(widget.user);
    }

    return FutureBuilder<UserModel?>(
      future: _profileLookup,
      builder: (context, snapshot) {
        return _buildResolvedAvatar(snapshot.data ?? widget.user);
      },
    );
  }

  Widget _buildResolvedAvatar(UserModel? resolvedUser) {
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

    if (resolvedPhotoType == 'upload' && resolvedPhotoUrl.isNotEmpty) {
      return _buildNetworkAvatar(resolvedPhotoUrl, resolvedName, resolvedRole);
    }

    if (resolvedRole != 'company' && resolvedPhotoType == 'avatar') {
      final avatar = AvatarConfig.getById(resolvedAvatarId);
      if (avatar != null) {
        return CircleAvatar(
          radius: widget.radius,
          backgroundColor: avatar.backgroundColor,
          child: Icon(
            avatar.icon,
            color: avatar.iconColor,
            size: widget.radius,
          ),
        );
      }
    }

    if (resolvedPhotoUrl.isNotEmpty) {
      return _buildNetworkAvatar(resolvedPhotoUrl, resolvedName, resolvedRole);
    }

    return _buildFallback(resolvedName, resolvedRole);
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
      return (resolvedUser.logo ?? '').trim();
    }

    return resolvedUser.profileImage.trim();
  }

  Widget _buildNetworkAvatar(String url, String name, String role) {
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
      return CircleAvatar(
        radius: widget.radius,
        backgroundColor: _fallbackColor(role),
        child: Icon(
          Icons.business,
          color: const Color(0xFF004E98),
          size: widget.radius,
        ),
      );
    }

    final initial = name.isNotEmpty
        ? name[0].toUpperCase()
        : (role == 'admin' ? 'A' : '?');

    return CircleAvatar(
      radius: widget.radius,
      backgroundColor: _fallbackColor(role),
      child: Text(
        initial,
        style: GoogleFonts.poppins(
          fontSize: widget.radius * 0.75,
          fontWeight: FontWeight.w600,
          color: _fallbackTextColor(role),
        ),
      ),
    );
  }

  Color _fallbackColor(String role) {
    switch (role) {
      case 'company':
        return const Color(0xFF004E98).withValues(alpha: 0.12);
      case 'admin':
        return const Color(0xFFFF8C00).withValues(alpha: 0.15);
      default:
        return const Color(0xFF3A6EA5).withValues(alpha: 0.2);
    }
  }

  Color _fallbackTextColor(String role) {
    switch (role) {
      case 'company':
        return const Color(0xFF004E98);
      case 'admin':
        return const Color(0xFFFF8C00);
      default:
        return const Color(0xFF004E98);
    }
  }
}
