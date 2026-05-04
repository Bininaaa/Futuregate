import 'package:flutter/foundation.dart';

import 'public_profile_service.dart';
import 'subscription_service.dart';

class PremiumStatusResolver {
  PremiumStatusResolver._();

  static final PremiumStatusResolver instance = PremiumStatusResolver._();

  final SubscriptionService _subscriptionService = SubscriptionService();
  final Map<String, bool> _cache = {};
  final Map<String, Future<bool>> _inFlight = {};

  bool? cachedActivePremium(String uid) {
    final normalizedUid = uid.trim();
    if (normalizedUid.isEmpty) {
      return false;
    }
    return _cache[normalizedUid];
  }

  void prime(String uid, bool isPremium) {
    final normalizedUid = uid.trim();
    if (normalizedUid.isEmpty) {
      return;
    }
    _cache[normalizedUid] = isPremium;
  }

  Future<bool> hasActivePremiumForStudent(String uid) {
    final normalizedUid = uid.trim();
    if (normalizedUid.isEmpty) {
      return Future.value(false);
    }

    final cached = _cache[normalizedUid];
    if (cached != null) {
      return Future.value(cached);
    }

    final existing = _inFlight[normalizedUid];
    if (existing != null) {
      return existing;
    }

    final request = _loadPremiumStatus(normalizedUid);
    _inFlight[normalizedUid] = request;
    request
        .then((value) {
          _cache[normalizedUid] = value;
        })
        .whenComplete(() {
          _inFlight.remove(normalizedUid);
        });
    return request;
  }

  Future<bool> _loadPremiumStatus(String uid) async {
    try {
      return await _subscriptionService.hasActivePremium(uid);
    } catch (_) {
      // Some roles cannot read other users' subscription documents directly.
      // Fall back to the public profile endpoint for display-only status.
    }

    try {
      final profile = await PublicProfileService.instance.fetchPublicProfile(
        uid,
      );
      return profile?.hasActivePremium == true;
    } catch (error) {
      debugPrint(
        'premium status public profile lookup failed for $uid: $error',
      );
    }

    return false;
  }
}
