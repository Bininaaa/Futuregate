import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum AppThemePreference {
  system('system'),
  light('light'),
  dark('dark');

  final String storageValue;

  const AppThemePreference(this.storageValue);

  ThemeMode get themeMode {
    return switch (this) {
      AppThemePreference.system => ThemeMode.system,
      AppThemePreference.light => ThemeMode.light,
      AppThemePreference.dark => ThemeMode.dark,
    };
  }

  String get title {
    return switch (this) {
      AppThemePreference.system => 'Use system theme',
      AppThemePreference.light => 'Light mode',
      AppThemePreference.dark => 'Dark mode',
    };
  }

  String get subtitle {
    return switch (this) {
      AppThemePreference.system => 'Follow your device appearance setting',
      AppThemePreference.light => 'Keep FutureGate bright and airy',
      AppThemePreference.dark => 'Use the premium dark workspace',
    };
  }

  static AppThemePreference fromStorageValue(String? value) {
    return AppThemePreference.values.firstWhere(
      (preference) => preference.storageValue == value,
      orElse: () => AppThemePreference.system,
    );
  }
}

class ThemeController extends ChangeNotifier {
  static const String storageKey = 'futuregate.theme_preference_v1';

  ThemeController({SharedPreferencesAsync? preferences})
    : _preferences = preferences ?? SharedPreferencesAsync();

  final SharedPreferencesAsync _preferences;

  AppThemePreference _preference = AppThemePreference.system;
  bool _loaded = false;

  AppThemePreference get preference => _preference;

  ThemeMode get themeMode => _preference.themeMode;

  bool get loaded => _loaded;

  Future<void> load() async {
    try {
      final storedValue = await _preferences.getString(storageKey);
      _preference = AppThemePreference.fromStorageValue(storedValue);
    } catch (_) {
      _preference = AppThemePreference.system;
    } finally {
      _loaded = true;
    }
  }

  Future<void> setPreference(AppThemePreference preference) async {
    if (_preference == preference && _loaded) {
      return;
    }

    _preference = preference;
    _loaded = true;
    notifyListeners();

    try {
      await _preferences.setString(storageKey, preference.storageValue);
    } catch (_) {
      // Theme switching should remain instant even if local persistence fails.
    }
  }
}
