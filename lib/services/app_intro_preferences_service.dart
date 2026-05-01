import 'package:shared_preferences/shared_preferences.dart';

class AppIntroPreferencesService {
  static const String getStartedKey = 'futuregate.has_seen_get_started_v1';
  static const String skipLaunchAnimationKey =
      'futuregate.skip_launch_animation_v1';
  static const String dailyWelcomeDateKey =
      'futuregate.daily_welcome_last_shown_v1';

  AppIntroPreferencesService({SharedPreferencesAsync? preferences})
    : _preferences = preferences;

  SharedPreferencesAsync? _preferences;

  SharedPreferencesAsync get _client =>
      _preferences ??= SharedPreferencesAsync();

  Future<bool> hasSeenGetStarted() async {
    try {
      return await _client.getBool(getStartedKey) ?? false;
    } catch (_) {
      return false;
    }
  }

  Future<void> markGetStartedSeen() async {
    await _client.setBool(getStartedKey, true);
  }

  Future<void> clearGetStartedSeen() async {
    await _client.remove(getStartedKey);
  }

  Future<bool> shouldSkipLaunchAnimation() async {
    try {
      return await _client.getBool(skipLaunchAnimationKey) ?? false;
    } catch (_) {
      return false;
    }
  }

  Future<void> setSkipLaunchAnimation(bool skip) async {
    await _client.setBool(skipLaunchAnimationKey, skip);
  }

  Future<bool> shouldShowDailyWelcome({required bool hasActivePremium}) async {
    if (hasActivePremium) return false;

    try {
      final stored = await _client.getString(dailyWelcomeDateKey);
      if (stored == null) return true;
      return stored != _todayKey();
    } catch (_) {
      return true;
    }
  }

  Future<void> markDailyWelcomeShown() async {
    await _client.setString(dailyWelcomeDateKey, _todayKey());
  }

  String _todayKey() {
    final today = DateTime.now();
    return '${today.year}-${today.month}-${today.day}';
  }
}
