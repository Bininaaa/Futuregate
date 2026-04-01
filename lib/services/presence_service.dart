import 'package:cloud_firestore/cloud_firestore.dart';

class PresenceService {
  PresenceService._();

  static final PresenceService instance = PresenceService._();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  String _lastUserId = '';
  bool? _lastIsOnline;

  Future<void> updatePresence({
    required String userId,
    required bool isOnline,
  }) async {
    final normalizedUserId = userId.trim();
    if (normalizedUserId.isEmpty) {
      return;
    }

    if (_lastUserId == normalizedUserId && _lastIsOnline == isOnline) {
      return;
    }

    _lastUserId = normalizedUserId;
    _lastIsOnline = isOnline;

    await _firestore.collection('users').doc(normalizedUserId).update({
      'isOnline': isOnline,
      'lastSeenAt': FieldValue.serverTimestamp(),
    });
  }
}
