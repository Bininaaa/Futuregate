class PremiumConfigModel {
  static const int normalStudentSavedLimit = 8;

  final num price;
  final String currency;
  final int durationDays; // default 180 (one semester)
  final int freeSavedLimit;
  final int premiumSavedLimit; // -1 = unlimited
  final int earlyAccessDefaultDelayHours;
  final bool premiumEnabled;
  final bool earlyAccessEnabled;
  final String premiumPlan;

  const PremiumConfigModel({
    required this.price,
    required this.currency,
    required this.durationDays,
    required this.freeSavedLimit,
    required this.premiumSavedLimit,
    required this.earlyAccessDefaultDelayHours,
    required this.premiumEnabled,
    required this.earlyAccessEnabled,
    required this.premiumPlan,
  });

  static const PremiumConfigModel defaults = PremiumConfigModel(
    price: 1500,
    currency: 'DZD',
    durationDays: 180,
    freeSavedLimit: normalStudentSavedLimit,
    premiumSavedLimit: -1, // unlimited
    earlyAccessDefaultDelayHours: 48,
    premiumEnabled: true,
    earlyAccessEnabled: true,
    premiumPlan: 'semester',
  );

  bool get hasUnlimitedSaved => premiumSavedLimit < 0;
  int get effectiveFreeSavedLimit {
    if (freeSavedLimit < 1) return normalStudentSavedLimit;
    if (freeSavedLimit > normalStudentSavedLimit) {
      return normalStudentSavedLimit;
    }
    return freeSavedLimit;
  }

  factory PremiumConfigModel.fromMap(Map<String, dynamic> map) {
    return PremiumConfigModel(
      price: (map['premiumPassPrice'] as num?) ?? defaults.price,
      currency: (map['premiumCurrency'] ?? defaults.currency).toString(),
      durationDays: _parseInt(
        map['premiumPassDurationDays'],
        defaults.durationDays,
      ),
      freeSavedLimit: _parseInt(
        map['freeSavedItemsLimit'],
        defaults.freeSavedLimit,
      ),
      premiumSavedLimit: _parseInt(
        map['premiumSavedItemsLimit'],
        defaults.premiumSavedLimit,
      ),
      earlyAccessDefaultDelayHours: _parseInt(
        map['earlyAccessDefaultDelayHours'],
        defaults.earlyAccessDefaultDelayHours,
      ),
      premiumEnabled: map['premiumEnabled'] != false,
      earlyAccessEnabled: map['earlyAccessEnabled'] != false,
      premiumPlan: (map['premiumPlan'] ?? defaults.premiumPlan).toString(),
    );
  }

  static int _parseInt(dynamic value, int fallback) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value) ?? fallback;
    return fallback;
  }
}
