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
}
