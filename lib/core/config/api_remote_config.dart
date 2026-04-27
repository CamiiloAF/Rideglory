import 'package:firebase_remote_config/firebase_remote_config.dart';

abstract final class ApiRemoteConfig {
  static const apiBaseUrlKey = 'api_base_url';
  static const useLocalApiKey = 'use_local_api';

  static Future<void> initialize(FirebaseRemoteConfig remoteConfig) async {
    await remoteConfig.setDefaults(const {
      apiBaseUrlKey: '',
      useLocalApiKey: false,
    });

    await remoteConfig.setConfigSettings(
      RemoteConfigSettings(
        fetchTimeout: const Duration(seconds: 10),
        minimumFetchInterval: const Duration(minutes: 5),
      ),
    );

    await remoteConfig.fetchAndActivate();
  }
}
