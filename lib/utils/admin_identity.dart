class AdminIdentity {
  AdminIdentity._();

  static const String publicName = 'FutureGate Admin';

  static String displayName({
    required String role,
    String? fullName,
    String? fallback,
  }) {
    if (role.trim().toLowerCase() == 'admin') {
      return publicName;
    }

    final name = (fullName ?? '').trim();
    if (name.isNotEmpty) {
      return name;
    }

    return (fallback ?? '').trim();
  }

  static String publisherLabel(String value) {
    final label = sanitizeLegacyAdminLabel(value);
    return label.isEmpty ? publicName : label;
  }

  static String sanitizeLegacyAdminLabel(String value) {
    final label = value.trim();
    if (label.isEmpty) {
      return label;
    }

    return _mentionsLegacyAvenir(label) ? publicName : label;
  }

  static bool _mentionsLegacyAvenir(String value) {
    final lower = value.toLowerCase();
    final normalized = lower.replaceAll(RegExp(r'[^a-z0-9]+'), '');
    return normalized.contains('avenirdz') ||
        lower.contains('avenir dz') ||
        lower.contains('avenir-dz') ||
        lower.contains('avenir_dz') ||
        (normalized.contains('admin') && normalized.contains('avenir'));
  }
}
