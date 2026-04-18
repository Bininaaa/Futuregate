import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Manages the app's selected locale with SharedPreferences persistence.
///
/// A [null] locale means "use the device default".
/// Supported language codes: `en`, `fr`, `ar`.
class LocaleController extends ChangeNotifier {
  static const String _storageKey = 'futuregate.locale_v1';

  static const List<Locale> supportedLocales = [
    Locale('en'),
    Locale('fr'),
    Locale('ar'),
  ];

  static String _activeLanguageCode =
      WidgetsBinding.instance.platformDispatcher.locale.languageCode;

  LocaleController({SharedPreferencesAsync? preferences})
    : _preferences = preferences ?? SharedPreferencesAsync();

  final SharedPreferencesAsync _preferences;

  Locale? _locale; // null = system / device default
  bool _loaded = false;

  /// The currently active locale. [null] means follow the device locale.
  Locale? get locale => _locale;

  static String get activeLanguageCode => _activeLanguageCode;

  bool get loaded => _loaded;

  /// Whether the current locale is RTL.
  bool get isRtl => _locale?.languageCode == 'ar';

  /// Load the persisted locale from SharedPreferences.
  Future<void> load() async {
    try {
      final stored = await _preferences.getString(_storageKey);
      _locale = _fromStorageValue(stored);
    } catch (_) {
      _locale = null;
    } finally {
      _refreshActiveLanguageCode(_locale);
      _loaded = true;
    }
  }

  /// Change the locale and persist the selection.
  Future<void> setLocale(Locale? locale) async {
    if (_locale == locale && _loaded) return;

    _locale = locale;
    _loaded = true;
    _refreshActiveLanguageCode(_locale);
    notifyListeners();

    try {
      if (locale == null) {
        await _preferences.remove(_storageKey);
      } else {
        await _preferences.setString(_storageKey, locale.languageCode);
      }
    } catch (_) {
      // Locale switching remains instant even if persistence fails.
    }
  }

  static Locale? _fromStorageValue(String? value) {
    if (value == null || value.isEmpty) return null;
    final supported = supportedLocales.where((l) => l.languageCode == value);
    if (supported.isEmpty) return null;
    return supported.first;
  }

  static void _refreshActiveLanguageCode(Locale? locale) {
    _activeLanguageCode =
        locale?.languageCode ??
        WidgetsBinding.instance.platformDispatcher.locale.languageCode;
  }
}
