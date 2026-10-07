import 'package:firebase_remote_config/firebase_remote_config.dart';

class FeatureFlagService {
  static const String _firstConnectionKey = 'first_connection_enabled';
  static const String _dailyFlashFirstConnectionKey =
      'daily_flash_first_connection_enabled';

  static final FirebaseRemoteConfig _remoteConfig =
      FirebaseRemoteConfig.instance;

  static bool _initialised = false;

  static Future<void> initialise() async {
    if (_initialised) {
      return;
    }

    await _remoteConfig.setDefaults(
      const <String, Object>{
        _firstConnectionKey: false,
        _dailyFlashFirstConnectionKey: false,
      },
    );

    await _remoteConfig.setConfigSettings(
      RemoteConfigSettings(
        fetchTimeout: const Duration(seconds: 10),
        minimumFetchInterval: const Duration(minutes: 15),
      ),
    );

    try {
      await _remoteConfig.fetchAndActivate();
    } catch (_) {
      // Keep the safe local defaults if Remote Config cannot be reached.
    }

    _initialised = true;
  }

  static Future<bool> isFirstConnectionEnabled() async {
    await initialise();
    return _remoteConfig.getBool(_firstConnectionKey);
  }

  static Future<bool> isDailyFlashFirstConnectionEnabled() async {
    await initialise();
    return _remoteConfig.getBool(_dailyFlashFirstConnectionKey);
  }
}
