import 'package:firebase_remote_config/firebase_remote_config.dart';
import 'package:flutter/foundation.dart';
import 'package:rideglory/core/config/api_remote_config.dart';
import 'package:rideglory/core/config/app_env.dart';

class ApiBaseUrlResolver {
  const ApiBaseUrlResolver(this._remoteConfig);

  final FirebaseRemoteConfig _remoteConfig;

  // Activated via --dart-define=USE_LOCAL_API=true (see .vscode/launch.json "Local API" config).
  static const _forceLocal = bool.fromEnvironment('USE_LOCAL_API');

  // El flavor llega por --dart-define-from-file=config/<flavor>.json.
  // En dev se apunta al backend local por defecto (ignorando Remote Config);
  // para apuntar a otro backend en dev, ajusta LOCAL_API_BASE_URL en `.env`.
  static const _flavor = String.fromEnvironment('FLAVOR');
  static const _isDevFlavor = _flavor == 'dev';

  String resolve() {
    final remoteBaseUrl = _remoteConfig
        .getString(ApiRemoteConfig.apiBaseUrlKey)
        .trim();

    final shouldUseLocalApi =
        _forceLocal || _isDevFlavor || remoteBaseUrl.isEmpty;

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
