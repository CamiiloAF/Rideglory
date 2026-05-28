/// Anonymous, privacy-preserving telemetry contract.
///
/// Implementations must never send recognized text or document images — only
/// the aggregate, anonymous event properties defined per call site.
abstract class AnalyticsService {
  Future<void> logEvent(String name, [Map<String, Object>? parameters]);
}
