import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/premium_config_model.dart';
import '../models/subscription_model.dart';

class PremiumService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  static const String _configCollection = 'appConfig';
  static const String _configDoc = 'premiumConfig';

  Future<PremiumConfigModel> getConfig() async {
    try {
      final doc = await _firestore
          .collection(_configCollection)
          .doc(_configDoc)
          .get();
      if (doc.exists && doc.data() != null) {
        return PremiumConfigModel.fromMap(doc.data()!);
      }
    } catch (_) {}
    return PremiumConfigModel.defaults;
  }

  Stream<PremiumConfigModel> configStream() {
    return _firestore
        .collection(_configCollection)
        .doc(_configDoc)
        .snapshots()
        .map((snap) {
          if (!snap.exists || snap.data() == null) {
            return PremiumConfigModel.defaults;
          }
          return PremiumConfigModel.fromMap(snap.data()!);
        });
  }

  // Helper methods used throughout the app

  bool hasActivePremium(SubscriptionModel? sub) => sub?.isActive ?? false;

  bool canApplyNow({
    required SubscriptionModel? sub,
    required bool premiumEarlyAccess,
    required DateTime? publicVisibleAt,
  }) {
    if (!premiumEarlyAccess) return true;
    if (publicVisibleAt == null) return true;
    if (DateTime.now().isAfter(publicVisibleAt)) return true;
    return hasActivePremium(sub);
  }

  bool isEarlyAccessLockedForUser({
    required SubscriptionModel? sub,
    required bool premiumEarlyAccess,
    required DateTime? publicVisibleAt,
  }) {
    if (!premiumEarlyAccess) return false;
    if (publicVisibleAt == null) return false;
    if (DateTime.now().isAfter(publicVisibleAt)) return false;
    return !hasActivePremium(sub);
  }

  Duration getRemainingEarlyAccessTime(DateTime? publicVisibleAt) {
    if (publicVisibleAt == null) return Duration.zero;
    final remaining = publicVisibleAt.difference(DateTime.now());
    return remaining.isNegative ? Duration.zero : remaining;
  }

  bool canSaveMoreItems({
    required SubscriptionModel? sub,
    required int currentCount,
    required PremiumConfigModel config,
  }) {
    if (hasActivePremium(sub)) {
      if (config.hasUnlimitedSaved) return true;
      return currentCount < config.premiumSavedLimit;
    }
    return currentCount < config.freeSavedLimit;
  }

  bool shouldShowPremiumBadge(SubscriptionModel? sub) => sub?.isActive ?? false;

  bool shouldPrioritizeApplication(SubscriptionModel? sub) =>
      sub?.isActive ?? false;

  // Admin methods

  Future<void> approveEarlyAccess({
    required String opportunityId,
    required String adminUid,
    required int delayHours,
  }) async {
    final publicVisibleAt = DateTime.now().add(
      Duration(hours: delayHours),
    );
    await _firestore.collection('opportunities').doc(opportunityId).update({
      'earlyAccessStatus': 'approved',
      'premiumEarlyAccess': true,
      'earlyAccessReviewedBy': adminUid,
      'earlyAccessReviewedAt': FieldValue.serverTimestamp(),
      'earlyAccessDurationHours': delayHours,
      'publicVisibleAt': Timestamp.fromDate(publicVisibleAt),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> rejectEarlyAccess({
    required String opportunityId,
    required String adminUid,
    required String reason,
  }) async {
    await _firestore.collection('opportunities').doc(opportunityId).update({
      'earlyAccessStatus': 'rejected',
      'premiumEarlyAccess': false,
      'earlyAccessReviewedBy': adminUid,
      'earlyAccessReviewedAt': FieldValue.serverTimestamp(),
      'earlyAccessRejectedReason': reason,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> makePostNormal(String opportunityId) async {
    await _firestore.collection('opportunities').doc(opportunityId).update({
      'earlyAccessStatus': 'none',
      'earlyAccessRequested': false,
      'premiumEarlyAccess': false,
      'publicVisibleAt': null,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> updateAdminConfig(Map<String, dynamic> updates) async {
    await _firestore
        .collection(_configCollection)
        .doc(_configDoc)
        .set(updates, SetOptions(merge: true));
  }

  // Company methods

  Future<void> requestEarlyAccess(String opportunityId) async {
    await _firestore.collection('opportunities').doc(opportunityId).update({
      'earlyAccessRequested': true,
      'earlyAccessStatus': 'pending',
      'requestedEarlyAccessAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }
}
