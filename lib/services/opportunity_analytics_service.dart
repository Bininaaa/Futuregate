import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

class OpportunityAnalyticsService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<void> recordView(String opportunityId) {
    return _increment(opportunityId, {'viewsCount': FieldValue.increment(1)});
  }

  Future<void> recordLockedApplyClick(String opportunityId) {
    return _increment(opportunityId, {
      'lockedApplyClicks': FieldValue.increment(1),
    });
  }

  Future<void> recordUpgradeModalView(String opportunityId) {
    return _increment(opportunityId, {
      'upgradeModalViews': FieldValue.increment(1),
    });
  }

  Future<void> recordUpgradeClick(String opportunityId) {
    return _increment(opportunityId, {
      'upgradeClicks': FieldValue.increment(1),
    });
  }

  Future<void> recordApplicationSubmitted(
    String opportunityId, {
    required bool isPremium,
  }) {
    return _increment(opportunityId, {
      'applicationsCount': FieldValue.increment(1),
      (isPremium ? 'premiumApplicationsCount' : 'freeApplicationsCount'):
          FieldValue.increment(1),
    });
  }

  Future<void> _increment(
    String opportunityId,
    Map<String, Object> fields,
  ) async {
    final id = opportunityId.trim();
    if (id.isEmpty || fields.isEmpty) {
      return;
    }

    try {
      await _firestore.collection('opportunities').doc(id).update(fields);
    } catch (error) {
      debugPrint('Opportunity analytics update failed for $id: $error');
    }
  }
}
