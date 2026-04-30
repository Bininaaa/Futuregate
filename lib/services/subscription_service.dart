import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/subscription_model.dart';

class SubscriptionService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Stream<SubscriptionModel?> subscriptionStream(String uid) {
    if (uid.isEmpty) return const Stream.empty();
    return _firestore
        .collection('subscriptions')
        .doc(uid)
        .snapshots()
        .map((snap) {
          if (!snap.exists || snap.data() == null) return null;
          final data = Map<String, dynamic>.from(snap.data()!);
          data['uid'] = snap.id;
          return SubscriptionModel.fromMap(data);
        });
  }

  Future<SubscriptionModel?> getSubscription(String uid) async {
    if (uid.isEmpty) return null;
    final doc = await _firestore.collection('subscriptions').doc(uid).get();
    if (!doc.exists || doc.data() == null) return null;
    final data = Map<String, dynamic>.from(doc.data()!);
    data['uid'] = doc.id;
    return SubscriptionModel.fromMap(data);
  }

  Future<bool> hasActivePremium(String uid) async {
    final sub = await getSubscription(uid);
    return sub?.isActive ?? false;
  }
}
