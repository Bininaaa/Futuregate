import 'package:cloud_firestore/cloud_firestore.dart';

class PaymentModel {
  final String id;
  final String uid;
  final String provider; // chargily
  final String checkoutId;
  final String checkoutUrl;
  final String status; // pending, paid, failed, cancelled
  final num amount;
  final String currency;
  final String plan;
  final Timestamp? createdAt;
  final Timestamp? paidAt;
  final Timestamp? failedAt;
  final String rawProviderStatus;
  final Map<String, dynamic> metadata;
  final bool livemode;
  final String mode; // test or live

  PaymentModel({
    required this.id,
    required this.uid,
    required this.provider,
    required this.checkoutId,
    required this.checkoutUrl,
    required this.status,
    required this.amount,
    required this.currency,
    required this.plan,
    this.createdAt,
    this.paidAt,
    this.failedAt,
    this.rawProviderStatus = '',
    this.metadata = const {},
    this.livemode = false,
    this.mode = 'test',
  });

  bool get isPaid => status == 'paid';
  bool get isPending => status == 'pending';
  bool get isFailed => status == 'failed';
  bool get isCancelled => status == 'cancelled';

  factory PaymentModel.fromMap(Map<String, dynamic> map) {
    return PaymentModel(
      id: (map['id'] ?? '').toString(),
      uid: (map['uid'] ?? '').toString(),
      provider: (map['provider'] ?? 'chargily').toString(),
      checkoutId: (map['checkoutId'] ?? '').toString(),
      checkoutUrl: (map['checkoutUrl'] ?? '').toString(),
      status: _normalizeStatus(map['status']),
      amount: (map['amount'] as num?) ?? 0,
      currency: (map['currency'] ?? 'DZD').toString(),
      plan: (map['plan'] ?? 'semester').toString(),
      createdAt: _parseTimestamp(map['createdAt']),
      paidAt: _parseTimestamp(map['paidAt']),
      failedAt: _parseTimestamp(map['failedAt']),
      rawProviderStatus: (map['rawProviderStatus'] ?? '').toString(),
      metadata: Map<String, dynamic>.from(
        (map['metadata'] is Map) ? map['metadata'] as Map : {},
      ),
      livemode: map['livemode'] == true,
      mode: (map['mode'] ?? 'test').toString(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'uid': uid,
      'provider': provider,
      'checkoutId': checkoutId,
      'checkoutUrl': checkoutUrl,
      'status': status,
      'amount': amount,
      'currency': currency,
      'plan': plan,
      'createdAt': createdAt,
      'paidAt': paidAt,
      'failedAt': failedAt,
      'rawProviderStatus': rawProviderStatus,
      'metadata': metadata,
      'livemode': livemode,
      'mode': mode,
    };
  }

  static String _normalizeStatus(dynamic value) {
    final s = (value ?? '').toString().trim().toLowerCase();
    const valid = {'pending', 'paid', 'failed', 'cancelled'};
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
