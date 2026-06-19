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

  // URL de producción horneada en el build (config/prod.json → PROD_API_BASE_URL).
  // Actúa como fallback cuando Remote Config no ha sido descargado aún
  // (primer arranque sin red). Remote Config sigue teniendo prioridad.
  static const _prodFallbackUrl = String.fromEnvironment(
    'PROD_API_BASE_URL',
    defaultValue: '',
  );

  String resolve() {
    if (_forceLocal || _isDevFlavor) {
      return _withoutTrailingSlash(_localBaseUrl);
    }

    final remoteBaseUrl = _remoteConfig
        .getString(ApiRemoteConfig.apiBaseUrlKey)
        .trim();

    if (remoteBaseUrl.isNotEmpty) {
      return _withoutTrailingSlash(remoteBaseUrl);
    }

    if (_prodFallbackUrl.isNotEmpty) {
      return _withoutTrailingSlash(_prodFallbackUrl);
    }

    return _withoutTrailingSlash(_localBaseUrl);
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
