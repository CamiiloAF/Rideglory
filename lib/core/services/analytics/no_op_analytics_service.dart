import 'package:injectable/injectable.dart';

import 'analytics_service.dart';

/// Implementación no-op para dev y tests.
///
/// Registrada en DI para los environments 'dev' y 'test', de modo que
/// ningún evento se envíe a Firebase Analytics durante desarrollo.
@Injectable(as: AnalyticsService)
@Environment('dev')
@Environment('test')
class NoOpAnalyticsService implements AnalyticsService {
  @override
  Future<void> logEvent(String name, [Map<String, Object>? parameters]) async {}

  @override
  Future<void> logScreenView(String screenName) async {}

  @override
  Future<void> setUserId(String hashedId) async {}

  @override
  Future<void> setUserProperty(String name, String value) async {}

  @override
  Future<void> setEnabled(bool enabled) async {}
}
