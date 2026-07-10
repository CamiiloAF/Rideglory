# Analytics & Crash Reporting

## Regla G0 — Un único punto de importación por SDK Firebase

Cada SDK de Firebase tiene exactamente UN archivo autorizado a importarlo en `lib/`:

| SDK | Archivo autorizado |
|-----|--------------------|
| `package:firebase_analytics` | `lib/core/services/analytics/firebase_analytics_service.dart` |

> **Crashlytics fue reemplazado por Sentry** (ver §"CrashReporter — Contrato" abajo). Ya no existe un import autorizado de `package:firebase_crashlytics` en el proyecto; el paquete fue removido de `pubspec.yaml`.

Los siguientes archivos son **excepciones legítimas** (infraestructura DI y código generado):
- `lib/core/di/firebase_module.dart` — provee `@lazySingleton` para los SDKs Firebase
- `lib/core/di/injection.config.dart` — generado automáticamente por `build_runner`; no editar a mano

**Verificación** (debe retornar 0 líneas fuera de los archivos legítimos):
```bash
grep -r "package:firebase_crashlytics" lib/   # debe retornar 0 líneas — el SDK fue removido

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
- `SentryCrashReporter` (`lib/core/services/crash/sentry_crash_reporter.dart`) — prod/dev, delega a `Sentry.captureException`. Reemplazó a `FirebaseCrashReporter`/Crashlytics.
- `NoOpCrashReporter` — env test, body vacío para que la suite no contacte servicios externos.

> **Dev:** los errores se registran solo en consola, nunca se envían a Sentry en modo debug (ver [[project_observability_sentry]] en memoria). El envío a Sentry queda gateado a builds no-debug.

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

---

## Catálogo de eventos — Fase 4 (observability-sentry)

### Nuevos eventos añadidos

Todos los nombres cumplen ≤ 40 chars y no contienen PII.

| Evento | Constante | Params | Descripción |
|--------|-----------|--------|-------------|
| `events_publish_attempted` | `AnalyticsEvents.eventsPublishAttempted` | `form_mode` | Intención de tap en publicar (antes del trabajo async). |
| `events_step_advanced` | `AnalyticsEvents.eventsStepAdvanced` | `step_index`, `step_name` | Rider avanzó al siguiente paso del wizard de creación. |
| `events_step_back` | `AnalyticsEvents.eventsStepBack` | `step_index`, `step_name` | Rider retrocedió al paso anterior del wizard de creación. |
| `events_create_abandoned` | `AnalyticsEvents.eventsCreateAbandoned` | `form_mode`, `abandoned_at_step` | Rider cerró el wizard sin publicar ni guardar borrador. |
| `registration_submit_attempted` | `AnalyticsEvents.registrationSubmitAttempted` | `form_mode` | Intención de tap en enviar inscripción (antes del trabajo async). |
| `home_empty_events_cta` | `AnalyticsEvents.homeEmptyEventsCta` | — | Tap en CTA "Ver eventos" en la tarjeta de home vacía. |

### Nuevo parámetro

| Parámetro | Constante | Tipo | Descripción |
|-----------|-----------|------|-------------|
| `abandoned_at_step` | `AnalyticsParams.abandonedAtStep` | `int` | Índice del paso (0-based) en que se abandonó el wizard. |

### Valores canónicos de `step_name` para wizard de creación de evento

| Valor | Constante | Paso (índice) |
|-------|-----------|---------------|
| `basics` | `AnalyticsParams.stepNameBasics` | 0 — Nombre, fecha, hora |
| `config` | `AnalyticsParams.stepNameConfig` | 1 — Tipo, dificultad, precio, aforo |
| `route`  | `AnalyticsParams.stepNameRoute`  | 2 — Punto de encuentro, destino, waypoints |
| `review` | `AnalyticsParams.stepNameReview` | 3 — Revisión final antes de publicar |

### Garantías no-PII

- `abandoned_at_step`: valor entero 0-3. No contiene id de evento, nombre, uid, ni ningún dato personal.
- `step_name`: enum cerrado de 4 valores. Sin texto libre.
- `form_mode`: enum cerrado (`create` | `edit`).

### Patrón `_terminalEventEmitted` (idempotencia de abandono)

`EventFormCubit` y `RegistrationFormCubit` mantienen un flag booleano `_terminalEventEmitted` que se activa cuando el flujo termina exitosamente (publicar, guardar borrador, enviar registro). El `close()` sobreescrito solo emite el evento de abandono si el flag sigue en `false`, evitando conteos dobles.
