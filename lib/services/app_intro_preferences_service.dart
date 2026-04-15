import 'package:shared_preferences/shared_preferences.dart';

class AppIntroPreferencesService {
  static const String getStartedKey = 'futuregate.has_seen_get_started_v1';
  static const String skipLaunchAnimationKey =
      'futuregate.skip_launch_animation_v1';

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
}
