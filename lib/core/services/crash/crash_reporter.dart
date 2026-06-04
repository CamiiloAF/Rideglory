/// Contrato de reporte de errores en tiempo de ejecución.
///
/// Abstracción Dart puro — sin imports Flutter ni Firebase.
/// Permite que capas superiores (e incluso domain) consuman este servicio
/// sin acoplar la implementación concreta.
abstract class CrashReporter {
  /// Reporta un error no fatal con stack trace opcional.
  Future<void> recordError(
    Object exception,
    StackTrace? stack, {
    String? reason,
    bool fatal = false,
  });

  /// Habilita o deshabilita la colección de reportes (opt-out o gating debug/test).
  Future<void> setEnabled(bool enabled);
}
