# PRD Normalizado — observability-sentry (Fase 3)

- **Generado (UTC):** 2026-06-12T04:59:46Z
- **Slug:** `observability-sentry`
- **Fuente:** `docs/plans/observability-sentry/phases/phase-03-flutter-sentry-reemplaza-crashlytics-enlazado-al.md`
- **Repos:** Flutter `/Users/cami/Developer/Personal/Rideglory` (esta fase no toca `rideglory-api`)

---

## 1 Objetivo

Migrar el crash reporting de la app Flutter de Firebase Crashlytics a Sentry, de forma que los crashes y errores de red lleguen a Sentry **solo en prod**, enlazados a la traza del backend via `sentry-trace`/`baggage`, sin doble reporte, sin fuga de PII y sin ninguna ventana sin cobertura de crashes.

La interfaz `CrashReporter` permanece como único punto de acoplamiento. El comportamiento visible hacia el usuario no cambia (mensajes de error siguen en español desde `rest_client_functions.dart`; el `traceId` nunca es copy visible).

> **Ventana de verificación (temporal):** mientras duren las fases de Sentry, `SentryFlutter.init` queda habilitado también en dev/debug (DSN presente, `beforeSend` no devuelve `null` en debug) para verificar la integración. La palanca es reversible (`kSentryDevVerify` via `--dart-define`). Al cerrar la última fase se debe revertir al comportamiento prod-only (DSN vacío en dev, `beforeSend → null` en debug, `environment` por flavor).

---

## 2 Por qué

- Firebase Crashlytics no permite correlacionar crashes de la app con trazas del backend. Sentry sí lo hace mediante la propagación de `sentry-trace`/`baggage` (Fase 2 ya entregó la continuación en el gateway).
- El proyecto necesita observabilidad end-to-end (móvil → gateway → microservicios) en una sola plataforma.
- Crashlytics no ofrece control granular por environment ni denylist PII centralizada; Sentry sí.
- La Fase 2 del plan ya configuró el backend (`rideglory-api`) para continuar el trace header. Esta fase cierra el extremo del cliente.

---

## 3 Alcance

### Entra
- Añadir `sentry_flutter` y `sentry_dio` a `pubspec.yaml`.
- Nueva implementación `SentryCrashReporter implements CrashReporter`, gateada por DI (`@Environment('prod')`).
- `NoOpCrashReporter` registrado en DI con `@Environment('dev') @Environment('test')`.
- Gating de DI: `configureDependencies()` deriva el environment (`kReleaseMode`/flavor) y lo pasa a `getIt.init(environment: ...)`.
- `SentryFlutter.init` gated en `main.dart` (DSN vacío en dev → no envía; `beforeSend → null` en debug; `environment` por flavor).
- Denylist PII Flutter en `lib/core/observability/pii_denylist.dart`, consumida desde `beforeSend`/`beforeBreadcrumb`.
- `dio.addSentry()` como último interceptor en `AppDio.create`, con `tracePropagationTargets` restringido al host de la API Rideglory.
- Mapeo `NetworkErrorClassification` → `level`/`fingerprint`/filtrado: 5xx/crashes como error events; 4xx de negocio y `FirebaseAuthException` esperadas como breadcrumb/log (sin alerta ni consumo de cuota de errores).
- Retiro de Crashlytics **después** de validar Sentry: `pubspec.yaml`, `firebase_module.dart`, piezas nativas iOS/Android.
- Reemplazo de `crashlytics.setCustomKey('api_base_url', ...)` por tag/scope de Sentry.
- Tests de gating debug/prod y de redacción PII.
- Subtarea DevOps: upload de dSYM (iOS) y mapping ProGuard (Android) en CI.

### No entra
- Cambios de backend (`rideglory-api`): la Fase 2 ya entregó la continuación de `sentry-trace`.
- Nuevas pantallas, copy visible o cambio del flujo de errores hacia el usuario.
- `SentryNavigatorObserver`, screen_view, Insights/taps (Fase 4).
- Tracing del canal WebSocket `/tracking/ws`.
- Migración del histórico de Crashlytics a Sentry.

---

## 4 Áreas afectadas

| Área | Archivos clave |
|------|---------------|
| DI / core | `lib/core/di/injection.dart`, `lib/core/di/firebase_module.dart` |
| Inicialización | `lib/main.dart` |
| Crash services | `lib/core/services/crash/sentry_crash_reporter.dart` (nuevo), `lib/core/services/crash/no_op_crash_reporter.dart`, `lib/core/services/crash/firebase_crash_reporter.dart` (retirar) |
| Observabilidad | `lib/core/observability/pii_denylist.dart` (nuevo) |
| HTTP | `lib/core/http/app_dio.dart` |
| Config por flavor | `config/dev.json`, `config/prod.json` (clave `SENTRY_DSN`) |
| Nativos iOS | `ios/Podfile`, `ios/Podfile.lock`, `ios/Runner.xcodeproj/project.pbxproj`, `ios/Runner/Info.plist` |
| Nativos Android | `android/app/build.gradle`, `android/build.gradle` |
| CI | GitHub Actions workflow de build (upload de símbolos) |
| Tests | `test/core/services/crash/sentry_crash_reporter_test.dart` (nuevo), `test/core/observability/pii_denylist_test.dart` (nuevo) |
| Evidencia | `docs/exec-runs/observability-sentry/phase-03-validacion-prod-like.md` (nuevo) |
| Docs | `docs/features/authentication.md` (si documenta crash reporting) |

---

## 5 Criterios de aceptación

1. `pubspec.yaml` declara `sentry_flutter` y `sentry_dio`; tras el retiro, `firebase_crashlytics` ya no aparece (grep en `pubspec.yaml` y en `lib/` → 0 coincidencias).
2. **Gating por DI verificable:** `SentryCrashReporter` está anotada `@Injectable(as: CrashReporter) @Environment('prod')` y `NoOpCrashReporter` con `@Environment('dev') @Environment('test')`; `configureDependencies()` deriva el environment (`kReleaseMode`/flavor) y lo pasa a `getIt.init(environment: ...)`; el call site en `main.dart` está actualizado. En test/dev, `getIt<CrashReporter>()` resuelve `NoOpCrashReporter`; en prod, `SentryCrashReporter`.
3. `SentryFlutter.init` está dentro del `runZonedGuarded` de `main.dart`, antes de `runApp`; con DSN vacío en dev no envía, y `beforeSend` retorna `null` en `kDebugMode`.
4. `dio.addSentry()` es el **último** interceptor de la cadena en `AppDio.create` y `tracePropagationTargets` está restringido al host de la API Rideglory (no aplica a hosts de terceros como Mapbox/Firebase Storage).
5. Un 5xx de red de la app produce un evento Sentry con la traza correlacionada con el backend (mismo `traceId`/`sentry-trace`); un 4xx de negocio o una `FirebaseAuthException` esperada **no** generan evento (verificable en el test de mapeo y en la validación prod-like).
6. **PII no se filtra:** existe `lib/core/observability/pii_denylist.dart` como constante Dart propia; `beforeSend` y `beforeBreadcrumb` la usan; el test `pii_denylist_test.dart` falla si alguna clave (`authorization`, `id_token`, `password`, `email`, teléfono, `soat`, `placa`, `vin`) aparece sin redactar en un evento de prueba.
7. El mapeo `NetworkErrorClassification` → `level`/`fingerprint`/`shouldReport` vive en `SentryCrashReporter`/`beforeSend`; `network_error_classifier.dart` no importa `package:sentry` (grep → 0).
8. `firebase_module.dart` ya no provee `FirebaseCrashlytics` y el provider `dio(...)` ya no recibe `FirebaseCrashlytics` ni llama `setCustomKey`; el valor `api_base_url` se setea como tag/scope de Sentry.
9. No queda doble reporte: un único crash genera un único evento (test de gating que cuenta reportes en prod-like = 1).
10. `dart analyze` sin errores nuevos y `flutter test` en verde tras el retiro de Crashlytics.
11. CI incluye un paso de upload de dSYM (iOS) y mapping ProGuard (Android) a Sentry; un crash de prod aparece con stack simbolizado.
12. **Evidencia de validación prod-like:** existe `docs/exec-runs/observability-sentry/phase-03-validacion-prod-like.md` con la prueba del crash no fatal + del 5xx, ambos con símbolos legibles y `traceId` correlacionado al backend; el retiro de Crashlytics (paso 9 del plan) ocurrió **después** de adjuntar esa evidencia.

---

## 6 Guardrails de regresión

- **G1 — Sin ventana de crash:** no retirar Crashlytics antes de tener evidencia prod-like en `phase-03-validacion-prod-like.md` (criterio 12). La secuencia es integrar+validar Sentry → recién retirar.
- **G2 — Sin doble reporte:** un único crash → exactamente un evento Sentry. No re-enganchar `FlutterError.onError`/`PlatformDispatcher.onError` fuera de Sentry; dejar que Sentry instale sus hooks y que `registerCrashHandlers` delegue en la interfaz.
- **G3 — Sin fuga de PII:** `pii_denylist.dart` cubre `authorization`, `id_token`, `password`, `email`, teléfono, `soat`, `placa`, `vin`. El test `pii_denylist_test.dart` debe estar en verde antes de habilitar el DSN de prod.
- **G4 — `network_error_classifier.dart` libre del SDK:** no importar `package:sentry` en el clasificador (grep CI → 0).
- **G5 — `tracePropagationTargets` acotado:** el header `sentry-trace` no se propaga a terceros (Mapbox, Firebase Storage, etc.); solo al host de la API Rideglory.
- **G6 — Gating dev/debug estricto:** con DSN vacío en dev no se envía nada a Sentry; `beforeSend` retorna `null` en `kDebugMode` (exceptuando la ventana de verificación temporal con `kSentryDevVerify`).
- **G7 — Sin colisión de DI:** durante la coexistencia Crashlytics+Sentry (pasos 3–8 del plan), ambas impls deben tener calificadores `@Environment` distintos. Si `build_runner` falla por doble binding, es un error de implementación, no de la herramienta.
- **G8 — Símbolos:** sin el upload de dSYM/ProGuard en CI, los crashes de prod salen sin stack simbolizado. Esta subtarea es criterio de done (criterio 11), no opcional.
- **G9 — Reversibilidad de la ventana temporal:** al cerrar la última fase de Sentry, revertir a comportamiento prod-only (DSN vacío en dev, `beforeSend → null` en debug, `environment` por flavor) antes de armar el PR final.

---

## 7 Constraints heredados

- **Clean Architecture:** `network_error_classifier.dart` (capa `core/http`) permanece libre del SDK de Sentry. El adaptador de tipos SDK (`SentryLevel`, `fingerprint`) vive exclusivamente en `SentryCrashReporter`/`beforeSend`.
- **Interface única:** `CrashReporter` es el único punto de acoplamiento; el código de producto nunca importa `package:sentry` directamente.
- **Sin usuarios reales:** refactors agresivos (retiro de Crashlytics nativo) son aceptables siempre que `dart analyze` y `flutter test` pasen en verde.
- **DTO Pattern B:** no aplica en esta fase (sin DTOs nuevos).
- **Localization:** no hay copy nuevo; no se tocan archivos `.arb`.
- **Un widget por archivo / sin métodos que retornan widgets:** no aplica en esta fase (sin UI nueva).
- **Texto oscuro sobre primario:** no aplica (sin UI).
- **Dependencia de Fase 2 (dura):** el criterio 5 (traza correlacionada) y la evidencia del criterio 12 requieren que el gateway ya propague `sentry-trace`/`baggage`. Sin Fase 2 completada, no se puede cerrar esta fase.
