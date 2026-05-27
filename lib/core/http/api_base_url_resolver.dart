import 'package:firebase_remote_config/firebase_remote_config.dart';
import 'package:flutter/foundation.dart';
import 'package:rideglory/core/config/api_remote_config.dart';
import 'package:rideglory/core/config/app_env.dart';

class ApiBaseUrlResolver {
  const ApiBaseUrlResolver(this._remoteConfig);

  final FirebaseRemoteConfig _remoteConfig;

  String resolve() {
    final remoteBaseUrl = _remoteConfig
        .getString(ApiRemoteConfig.apiBaseUrlKey)
        .trim();

    final shouldUseLocalApi = remoteBaseUrl.isEmpty;
    //final shouldUseLocalApi = true;

    final baseUrl = shouldUseLocalApi ? _localBaseUrl : remoteBaseUrl;
    return _withoutTrailingSlash(baseUrl);
  }

  String get _localBaseUrl {
    // Explicit override from `.env` (e.g. the Mac's LAN IP) takes precedence so
    // physical devices and emulators can share the same backend instance.
    // Gated on `kDebugMode` as defense-in-depth: even if the env value sneaks
    // into a release build, the local URL is never used in release.
    if (kDebugMode) {
      final override = AppEnv.localApiBaseUrl?.trim();
      if (override != null && override.isNotEmpty) {
        return override;
      }
    }

    if (kIsWeb) {
      return 'http://localhost:3000/api';
    }

    return switch (defaultTargetPlatform) {
      TargetPlatform.android => 'http://10.0.2.2:3000/api',
      _ => 'http://localhost:3000/api',
    };
  }

  String _withoutTrailingSlash(String value) {
    if (value.endsWith('/')) {
      return value.substring(0, value.length - 1);
    }
    return value;
  }
}
