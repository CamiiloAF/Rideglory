import 'package:envied/envied.dart';

part 'app_env.g.dart';

@Envied(path: '.env', allowOptionalFields: true, useConstantCase: true)
abstract class AppEnv {
  @EnviedField(optional: true)
  static const String? firebaseAndroidApiKey = _AppEnv.firebaseAndroidApiKey;

  @EnviedField(optional: true)
  static const String? firebaseAndroidAppId = _AppEnv.firebaseAndroidAppId;

  @EnviedField(optional: true)
  static const String? firebaseIosApiKey = _AppEnv.firebaseIosApiKey;

  @EnviedField(optional: true)
  static const String? firebaseIosAppId = _AppEnv.firebaseIosAppId;

  @EnviedField(optional: true)
  static const String? firebaseMessagingSenderId =
      _AppEnv.firebaseMessagingSenderId;

  @EnviedField(optional: true)
  static const String? firebaseProjectId = _AppEnv.firebaseProjectId;

  @EnviedField(optional: true)
  static const String? firebaseStorageBucket = _AppEnv.firebaseStorageBucket;

  @EnviedField(optional: true)
  static const String? firebaseAndroidClientId = _AppEnv.firebaseAndroidClientId;

  @EnviedField(optional: true)
  static const String? firebaseIosClientId = _AppEnv.firebaseIosClientId;

  @EnviedField(optional: true)
  static const String? firebaseIosBundleId = _AppEnv.firebaseIosBundleId;

  /// Mapbox public token (pk.*) used to initialize the Mapbox SDK at runtime.
  @EnviedField(optional: true)
  static const String? mapboxPublicToken = _AppEnv.mapboxPublicToken;

  /// Optional override for the local API base URL. When set, [ApiBaseUrlResolver]
  /// uses this value instead of the platform-specific localhost defaults
  /// (`10.0.2.2` for the Android emulator, `localhost` for iOS sim / web).
  ///
  /// Required when running on a **physical device** against a local backend:
  /// point it at the Mac's LAN IP (e.g. `http://192.168.20.94:3000/api`) so the
  /// device can reach the gateway over Wi-Fi. The same value also works for the
  /// emulator/simulator, so you can leave it set during normal development.
  @EnviedField(optional: true)
  static const String? localApiBaseUrl = _AppEnv.localApiBaseUrl;
}
