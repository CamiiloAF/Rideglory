# Analytics & Crash Reporting

## Regla G0 — Un único punto de importación por SDK Firebase

Cada SDK de Firebase tiene exactamente UN archivo autorizado a importarlo en `lib/`:

| SDK | Archivo autorizado |
|-----|--------------------|
| `package:firebase_analytics` | `lib/core/services/analytics/firebase_analytics_service.dart` |
| `package:firebase_crashlytics` | `lib/core/services/crash/firebase_crash_reporter.dart` |

Los siguientes archivos son **excepciones legítimas** (infraestructura DI y código generado):
- `lib/core/di/firebase_module.dart` — provee `@lazySingleton` para los SDKs Firebase
- `lib/core/di/injection.config.dart` — generado automáticamente por `build_runner`; no editar a mano

**Verificación** (debe retornar 0 líneas fuera de los archivos legítimos):
```bash
grep -r "package:firebase_crashlytics" lib/ \
  | grep -v "lib/core/services/crash/firebase_crash_reporter.dart" \
  | grep -v "lib/core/di/firebase_module.dart" \
  | grep -v "lib/core/di/injection.config.dart"

grep -r "package:firebase_analytics" lib/ \
  | grep -v "lib/core/services/analytics/firebase_analytics_service.dart" \
  | grep -v "lib/core/di/firebase_module.dart" \
  | grep -v "lib/core/di/injection.config.dart"
```

---

## CrashReporter — Contrato

```dart
// lib/core/services/crash/crash_reporter.dart
abstract class CrashReporter {
  Future<void> recordError(
    Object exception,
    StackTrace? stack, {
    String? reason,
    bool fatal = false,
  });
  Future<void> setEnabled(bool enabled);
}
```

**Implementaciones:**
- `FirebaseCrashReporter` — prod/dev, delega a `FirebaseCrashlytics` (único import del SDK)
- `NoOpCrashReporter` — env test, body vacío para que la suite no contacte Firebase

**Gating en `main.dart`:** Los handlers `FlutterError.onError` y `PlatformDispatcher.onError` solo se registran cuando `!kDebugMode`. El zone handler de `runZonedGuarded` también gatéa `!kDebugMode`.

**Invariante de orden en `main()`:**
1. `configureDependencies()` — DI lista
2. Init defensivo: `try { await getIt<CrashReporter>().setEnabled(!kDebugMode); } catch (_) {}`
3. Registro de handlers (post-DI, pre-runApp)
4. `runZonedGuarded(() => runApp(...), handler)`

---

## AnalyticsService — Contrato ampliado

```dart
abstract class AnalyticsService {
  Future<void> logEvent(String name, [Map<String, Object>? parameters]);

  // Fases futuras (actualmente implementadas con body vacío como default)
  Future<void> logScreenView(String screenName) async {}
  Future<void> setUserId(String hashedId) async {}
  Future<void> setUserProperty(String name, String value) async {}
  Future<void> setEnabled(bool enabled) async {}
}
```

**Non-breaking:** Las 4 firmas nuevas tienen implementación default en la clase abstracta. Cualquier subclase existente (incluida `FirebaseAnalyticsService`) puede sobreescribirlas sin romper compilación.

---

## Cumplimiento ScanSoatUseCase

`ScanSoatUseCase` consume `AnalyticsService.logEvent(...)` — la única firma original. Los cambios a `AnalyticsService` son non-breaking: se añadieron 4 métodos con default impl. `ScanSoatUseCase` compila sin modificación y sigue cumpliendo G0 (no importa ningún SDK Firebase directamente).
