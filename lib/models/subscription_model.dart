import 'package:cloud_firestore/cloud_firestore.dart';

class SubscriptionModel {
  final String uid;
  final String role;
  final String plan;
  final String status; // active, expired, cancelled, pending, failed
  final String provider; // chargily
  final num amount;
  final String currency;
  final Timestamp? startedAt;
  final Timestamp? expiresAt;
  final String checkoutId;
  final String paymentId;
  final Timestamp? lastVerifiedAt;
  final Timestamp? createdAt;
  final Timestamp? updatedAt;
  final String mode; // test or live

  SubscriptionModel({
    required this.uid,
    required this.role,
    required this.plan,
    required this.status,
    required this.provider,
    required this.amount,
    required this.currency,
    this.startedAt,
    this.expiresAt,
    this.checkoutId = '',
    this.paymentId = '',
    this.lastVerifiedAt,
    this.createdAt,
    this.updatedAt,
    this.mode = 'test',
  });

  bool get isActive {
    if (status != 'active') return false;
    if (expiresAt == null) return false;
    return expiresAt!.toDate().isAfter(DateTime.now());
  }

  bool get isExpired {
    if (expiresAt == null) return false;
    return expiresAt!.toDate().isBefore(DateTime.now());
  }

  bool get isPending => status == 'pending';
  bool get isFailed => status == 'failed';
  bool get isCancelled => status == 'cancelled';

  DateTime? get expiresAtDate => expiresAt?.toDate();
  DateTime? get startedAtDate => startedAt?.toDate();

  factory SubscriptionModel.fromMap(Map<String, dynamic> map) {
    return SubscriptionModel(
      uid: (map['uid'] ?? '').toString(),
      role: (map['role'] ?? 'student').toString(),
      plan: (map['plan'] ?? 'semester').toString(),
      status: _normalizeStatus(map['status']),
      provider: (map['provider'] ?? 'chargily').toString(),
      amount: (map['amount'] as num?) ?? 0,
      currency: (map['currency'] ?? 'DZD').toString(),
      startedAt: _parseTimestamp(map['startedAt']),
      expiresAt: _parseTimestamp(map['expiresAt']),
      checkoutId: (map['checkoutId'] ?? '').toString(),
      paymentId: (map['paymentId'] ?? '').toString(),
      lastVerifiedAt: _parseTimestamp(map['lastVerifiedAt']),
      createdAt: _parseTimestamp(map['createdAt']),
      updatedAt: _parseTimestamp(map['updatedAt']),
      mode: (map['mode'] ?? 'test').toString(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'role': role,
      'plan': plan,
      'status': status,
      'provider': provider,
      'amount': amount,
      'currency': currency,
      'startedAt': startedAt,
      'expiresAt': expiresAt,
      'checkoutId': checkoutId,
      'paymentId': paymentId,
      'lastVerifiedAt': lastVerifiedAt,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
      'mode': mode,
    };
  }

  static String _normalizeStatus(dynamic value) {
    final s = (value ?? '').toString().trim().toLowerCase();
    const valid = {'active', 'expired', 'cancelled', 'pending', 'failed'};
    return valid.contains(s) ? s : 'pending';
  }

  static Timestamp? _parseTimestamp(dynamic value) {
    if (value is Timestamp) return value;
    if (value is String && value.isNotEmpty) {
      final parsed = DateTime.tryParse(value);
      if (parsed != null) return Timestamp.fromDate(parsed);
    }
    return null;
  }
}
