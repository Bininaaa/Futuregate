import 'package:flutter/material.dart';

import '../services/premium_status_resolver.dart';
import 'premium_badge.dart';

class ProfilePremiumBadge extends StatefulWidget {
  final String? userId;
  final bool? isPremium;
  final PremiumBadgeSize size;
  final bool showLabel;

  const ProfilePremiumBadge({
    super.key,
    required this.userId,
    this.isPremium,
    this.size = PremiumBadgeSize.small,
    this.showLabel = true,
  });

  @override
  State<ProfilePremiumBadge> createState() => _ProfilePremiumBadgeState();
}

class _ProfilePremiumBadgeState extends State<ProfilePremiumBadge> {
  late Future<bool> _isPremiumFuture;

  @override
  void initState() {
    super.initState();
    _isPremiumFuture = _loadPremiumStatus();
  }

  @override
  void didUpdateWidget(covariant ProfilePremiumBadge oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.userId != oldWidget.userId ||
        widget.isPremium != oldWidget.isPremium) {
      _isPremiumFuture = _loadPremiumStatus();
    }
  }

  Future<bool> _loadPremiumStatus() async {
    final explicitStatus = widget.isPremium;
    if (explicitStatus != null) {
      return explicitStatus;
    }

    final uid = (widget.userId ?? '').trim();
    if (uid.isEmpty) {
      return false;
    }

    return PremiumStatusResolver.instance.hasActivePremiumForStudent(uid);
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<bool>(
      future: _isPremiumFuture,
      builder: (context, snapshot) {
        if (snapshot.data != true) {
          return const SizedBox.shrink();
        }

        return PremiumBadge(size: widget.size, showLabel: widget.showLabel);
      },
    );
  }
}
