/// Anonymous, privacy-preserving telemetry contract.
///
/// Implementations must never send recognized text or document images — only
/// the aggregate, anonymous event properties defined per call site.
abstract class AnalyticsService {
  Future<void> logEvent(String name, [Map<String, Object>? parameters]);

  // Nuevas firmas — fases futuras las implementan; esta fase declara e implementa vacío.
  Future<void> logScreenView(String screenName) async {}
  Future<void> setUserId(String hashedId) async {}
  Future<void> setUserProperty(String name, String value) async {}
  Future<void> setEnabled(bool enabled) async {}
}
