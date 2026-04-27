import 'package:firebase_remote_config/firebase_remote_config.dart';
import 'package:flutter/foundation.dart';
import 'package:rideglory/core/config/api_remote_config.dart';

class ApiBaseUrlResolver {
  const ApiBaseUrlResolver(this._remoteConfig);

  final FirebaseRemoteConfig _remoteConfig;

  String resolve() {
    final remoteBaseUrl = _remoteConfig
        .getString(ApiRemoteConfig.apiBaseUrlKey)
        .trim();
    final shouldUseLocalApi =
        _remoteConfig.getBool(ApiRemoteConfig.useLocalApiKey) ||
        remoteBaseUrl.isEmpty;

    final baseUrl = shouldUseLocalApi ? _localBaseUrl : remoteBaseUrl;
    return _withoutTrailingSlash(baseUrl);
  }

  String get _localBaseUrl {
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
