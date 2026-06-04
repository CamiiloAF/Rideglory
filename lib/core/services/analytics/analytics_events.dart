/// Catálogo centralizado de nombres de evento para Firebase Analytics.
///
/// Convenciones de naming:
/// - snake_case, prefijo por feature (p.ej. `soat_`, `auth_`, `event_`).
/// - Máximo 40 caracteres por nombre (límite GA4 — verificar con `.length`
///   si se añaden nombres largos).
/// - No usar palabras reservadas de GA4 (e.g. `login` sin prefijo está
///   reservado; usar `auth_login` si se instrumenta en fases siguientes).
///
/// Política no-PII (GA4 / Crashlytics):
/// Ningún nombre de evento puede incluir ids dinámicos, emails, nombres,
/// placas, VIN, coordenadas ni nombres de aseguradoras. Solo categorías
/// y acciones estables.
abstract final class AnalyticsEvents {
  // ---------------------------------------------------------------------------
  // SOAT
  // ---------------------------------------------------------------------------

  /// El usuario inicia un escaneo de SOAT (primera acción del flujo).
  /// Max 40 chars: 'soat_scan_attempted'.length == 19. ✓
  static const String soatScanAttempted = 'soat_scan_attempted';

  /// El escaneo terminó con éxito y se prefillaron los campos del SOAT.
  /// Max 40 chars: 'soat_scan_success'.length == 17. ✓
  static const String soatScanSuccess = 'soat_scan_success';

  /// El escaneo falló (baja confianza, sin texto, validación, etc.).
  /// Max 40 chars: 'soat_scan_failed'.length == 16. ✓
  static const String soatScanFailed = 'soat_scan_failed';
}
