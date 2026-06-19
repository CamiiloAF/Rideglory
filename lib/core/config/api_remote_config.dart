import 'package:firebase_remote_config/firebase_remote_config.dart';

abstract final class ApiRemoteConfig {
  static const apiBaseUrlKey = 'api_base_url';
  static const minRequiredVersionKey = 'min_required_version';
  static const googleSignInIosEnabledKey = 'google_sign_in_ios_enabled';

  static Future<void> initialize(FirebaseRemoteConfig remoteConfig) async {
    await remoteConfig.setDefaults(const {
      apiBaseUrlKey: '',
      minRequiredVersionKey: '',
      googleSignInIosEnabledKey: false,
    });

    await remoteConfig.setConfigSettings(
      RemoteConfigSettings(
        fetchTimeout: const Duration(seconds: 10),
        minimumFetchInterval: const Duration(minutes: 5),
      ),
    );

    // fetchAndActivate puede fallar en el primer arranque si no hay red o
    // Firebase Remote Config no está disponible. En ese caso continuamos con
    // los defaults: la app arranca normalmente y reintenta en el próximo ciclo.
    try {
      await remoteConfig.fetchAndActivate();
    } catch (_) {}
  }
}
