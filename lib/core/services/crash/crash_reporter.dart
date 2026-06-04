/// Contrato de reporte de errores en tiempo de ejecución.
///
/// Abstracción Dart puro — sin imports Flutter ni Firebase.
/// Permite que capas superiores (e incluso domain) consuman este servicio
/// sin acoplar la implementación concreta.
abstract class CrashReporter {
  /// Reporta un error no fatal con stack trace opcional.
  ///
  /// [information] — lista de pares clave-valor no-PII (p.ej.
  /// `['error_category=network', 'http_status=500']`) que se adjuntan
  /// al reporte en Crashlytics. Cada entrada debe cumplir los límites GA4
  /// (clave ≤40 chars, valor ≤100 chars). Nunca incluir ids, email, placa
  /// ni datos dinámicos de usuario.
  Future<void> recordError(
    Object exception,
    StackTrace? stack, {
    String? reason,
    bool fatal = false,
    List<String> information = const [],
  });

  /// Habilita o deshabilita la colección de reportes (opt-out o gating debug/test).
  Future<void> setEnabled(bool enabled);
}
