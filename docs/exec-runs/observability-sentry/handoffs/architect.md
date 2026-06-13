# Architect handoff — observability-sentry (Fase 3)

**Date:** 2026-06-12T05:08:28Z
**Status:** done (rev 2 — correcciones de Auditor Opus)
**Slug:** observability-sentry

---

## Decisiones

| # | Decisión | Rationale |
|---|----------|-----------|
| D1 | `SentryCrashReporter` anotada `@Injectable(as: CrashReporter) @Environment('prod')` — `NoOpCrashReporter` anotada `@Environment('dev') @Environment('test')` | Bindings actuales (injection.config.dart) usan `factory` sin environment qualifier. El gating por DI requiere pasar `environment:` a `getIt.init()` desde `configureDependencies()`. |
| D2 | `configureDependencies()` recibe un `String environment` derivado de `kReleaseMode` (y opcionalmente del flavor FLAVOR env-var). En prod: `'prod'`; en dev/debug: `'dev'`. | Permite que `build_runner` genere el filtro correcto sin lógica ad-hoc. |
| D3 | `NoOpCrashReporter` pasa a ser `@injectable` con `@Environment('dev') @Environment('test')` (actualmente es un test double manual sin anotación DI). No hay doble binding mientras `FirebaseCrashReporter` pierda su anotación `@Injectable(as: CrashReporter)` y sea eliminada en el paso correcto. | Clean Architecture: la interfaz sigue siendo el único punto de acoplamiento. |
| D4 | **CORREGIDO (Auditor rev 2):** `SENTRY_DSN` se inyecta EXCLUSIVAMENTE via `--dart-define-from-file=config/<flavor>.json` y se lee en Dart como `const String.fromEnvironment('SENTRY_DSN', defaultValue: '')`. NO se declara como `@EnviedField` en `app_env.dart` — `envied` no procesa `--dart-define`, solo lee el archivo `.env` en tiempo de generación. Agregar `SENTRY_DSN` a `@Envied` crearía un campo siempre vacío (o roto) al correr con flavors. La fuente única es `config/dev.json` (vacío) y `config/prod.json` (DSN real), consumidos por `--dart-define-from-file` en el comando `flutter run/build`. | Coherencia con el mecanismo de flavors existente. Evita la trampa de `envied` + `--dart-define`. |
| D5 | `SentryFlutter.init` va dentro del `runZonedGuarded` existente en `main.dart`, antes de `runApp` y después de `configureDependencies()`. DSN se lee con `const String.fromEnvironment('SENTRY_DSN', defaultValue: '')`. `beforeSend` retorna `null` cuando `kDebugMode && !kSentryDevVerify`. | Sin este orden, los crashes del init de Firebase quedan sin cobertura. |
| D6 | `dio.addSentry()` se añade como **último** interceptor en `AppDio.create`, después del `LogInterceptor` existente. `tracePropagationTargets` restringido al host de la API Rideglory (extraído de `ApiBaseUrlResolver`). | G5 del PRD: el header `sentry-trace` no debe propagarse a Mapbox, Firebase Storage, ni otros terceros. |
| D7 | Denylist PII (`lib/core/observability/pii_denylist.dart`) es una constante Dart pura: `Set<String>`. La lógica de scrub la consumen `beforeSend` y `beforeBreadcrumb` en `SentryCrashReporter`. `network_error_classifier.dart` no importa `package:sentry` (cumple G4). | Separación de responsabilidades. Classifier produce `NetworkErrorClassification`; `SentryCrashReporter` traduce a `SentryLevel`/fingerprint. |
| D8 | El `CrashReporter.recordError` actual acepta `List<String> information` (pares clave-valor). `SentryCrashReporter.recordError` usa esa lista para setear tags en el scope Sentry. El `reason` se mapea a `hint`. Sin breaking change en la interfaz. | La interfaz `CrashReporter` permanece agnóstica del SDK. |
| D9 | `crashlytics.setCustomKey('api_base_url', resolvedUrl)` en `firebase_module.dart` se reemplaza por `Sentry.configureScope((s) => s.setTag('api_base_url', resolvedUrl))` en `SentryFlutter.init` o en `AppDio.create`. | Mantiene el mismo observability sin Crashlytics. |
| D10 | Retiro de Crashlytics en secuencia: (1) integrar Sentry, (2) obtener evidencia prod-like en `phase-03-validacion-prod-like.md`, (3) recién entonces eliminar `firebase_crashlytics` de `pubspec.yaml`, `firebase_module.dart`, `build.gradle.kts`, `settings.gradle.kts`, `project.pbxproj` y el build phase Crashlytics. | Guardrail G1: sin ventana sin cobertura. |
| D11 | `kSentryDevVerify` es un `bool const` leído desde `--dart-define` (`const bool.fromEnvironment('SENTRY_DEV_VERIFY')`). Sin ese flag el `beforeSend` en dev/debug retorna `null`. Reversible antes del PR final (G9). | Ventana de verificación temporal del PRD §1. |
| D12 | **NUEVO (Auditor rev 2):** Los archivos de WIP del wizard de eventos (`lib/features/events/presentation/form/widgets/steps/**` y `lib/features/events/presentation/form/screens/**` — 8 archivos con cambios en working tree) quedan **fuera del scope de esta fase**. No deben incluirse en el diff de observability-sentry. Si el desarrollador tiene esos cambios en su working tree, debe guardarlos (`git stash`) antes de hacer el PR de esta fase. | Aislamiento de scope: no mezclar el WIP del wizard de eventos con la migración a Sentry. |
| D13 | **NUEVO (Auditor rev 2):** `docs/exec-runs/observability-sentry/phase-03-validacion-prod-like.md` debe crearse con evidencia real (crash no-fatal + 5xx simbolizados + traceId correlacionado) ANTES de ejecutar el retiro de Crashlytics (paso D10). Hoy ese artefacto no existe — es un bloqueante de criterio 12 y guardrail G1. | Sin evidencia no hay retiro. |

---

## Change map

| File | Action | Reason | Risk |
|------|--------|--------|------|
| `pubspec.yaml` | modify | Añadir `sentry_flutter ^8.x`, `sentry_dio ^8.x`; eventualmente retirar `firebase_crashlytics` (post-evidencia) | low |
| `config/dev.json` | modify | Añadir clave `SENTRY_DSN` con valor vacío `""` | low |
| `config/prod.json` | modify | Añadir clave `SENTRY_DSN` con DSN real de Sentry dashboard | low |
| `config/dev.json.example` | modify | Añadir placeholder `SENTRY_DSN: ""` | low |
| `config/prod.json.example` | modify | Añadir placeholder `SENTRY_DSN: "<obtener-de-sentry-dashboard>"` | low |
| `lib/core/di/injection.dart` | modify | `configureDependencies({String environment = 'dev'})` — pasa `environment` a `getIt.init(environment: ...)` | med |
| `lib/core/di/firebase_module.dart` | modify | Eliminar provider de `FirebaseCrashlytics`; eliminar parámetro `crashlytics` del provider `dio`; el tag `api_base_url` se setea via Sentry scope | med |
| `lib/core/di/injection.config.dart` | modify | Regenerado por `build_runner` tras cambios de anotaciones | med |
| `lib/main.dart` | modify | `SentryFlutter.init` dentro de `runZonedGuarded`; `configureDependencies(environment: ...)` con derivación; `beforeSend` gating; `const String.fromEnvironment('SENTRY_DSN')` | med |
| `lib/core/services/crash/sentry_crash_reporter.dart` | create | Impl Sentry con `@Injectable(as: CrashReporter) @Environment('prod')`; scrub PII; mapeo `NetworkErrorClassification` → `SentryLevel`/fingerprint | med |
| `lib/core/services/crash/no_op_crash_reporter.dart` | modify | Añadir `@injectable @Environment('dev') @Environment('test')` | low |
| `lib/core/services/crash/firebase_crash_reporter.dart` | delete | Retirado tras validación Sentry (D10) — SOLO después de que `phase-03-validacion-prod-like.md` exista | high |
| `lib/core/observability/pii_denylist.dart` | create | Constante Dart pura con claves PII prohibidas (`authorization`, `id_token`, `password`, `email`, `phone`, `soat`, `placa`, `vin`) | low |
| `lib/core/http/app_dio.dart` | modify | `dio.addSentry(...)` como último interceptor; `tracePropagationTargets` restringido al host Rideglory | low |
| `android/app/build.gradle.kts` | modify | Eliminar plugin `com.google.firebase.crashlytics` (post-evidencia); añadir paso upload mapping Sentry | med |
| `android/settings.gradle.kts` | modify | Eliminar `com.google.firebase.crashlytics` del classpath (post-evidencia) | low |
| `ios/Runner.xcodeproj/project.pbxproj` | modify | Eliminar build phase Crashlytics (post-evidencia); añadir script upload dSYM Sentry | med |
| `ios/Podfile` / `ios/Podfile.lock` | modify | Regenerado tras `flutter pub get`/`pod install`; FirebaseCrashlytics pod desaparece (post-evidencia) | low |
| `.github/workflows/ci.yml` | modify | Añadir secrets `SENTRY_AUTH_TOKEN`, `SENTRY_ORG`, `SENTRY_PROJECT`; paso upload dSYM (iOS) y mapping (Android) | med |
| `test/core/services/crash/sentry_crash_reporter_test.dart` | create | Test gating debug/prod (exactamente 1 evento), test mapeo 5xx→reporte, 4xx→skip | low |
| `test/core/observability/pii_denylist_test.dart` | create | Test que ninguna clave PII pasa sin redactar en evento Sentry de prueba | low |
| `docs/exec-runs/observability-sentry/phase-03-validacion-prod-like.md` | create | Evidencia crash no-fatal + 5xx con traceId correlacionado (bloqueante D13/criterio 12) | low |
| `docs/exec-runs/observability-sentry/analysis/ENV_DELTA.md` | modify | Corregir mecanismo de inyección SENTRY_DSN (D4 rev 2) | low |

**Archivos EXCLUIDOS del scope (D12):**
- `lib/features/events/presentation/form/widgets/steps/navigation_row.dart`
- `lib/features/events/presentation/form/widgets/steps/publish_row.dart`
- `lib/features/events/presentation/form/widgets/steps/review_card.dart`
- `lib/features/events/presentation/form/widgets/steps/review_row.dart`
- `lib/features/events/presentation/form/widgets/steps/step_circle.dart`
- `lib/features/events/presentation/form/screens/route_cta_bar.dart`
- `lib/features/events/presentation/form/screens/route_map_area.dart`
- `lib/features/events/presentation/form/screens/route_search_bar.dart`

**Nota de secuencia crítica:** `firebase_crash_reporter.dart` y los archivos nativos/Gradle se eliminan SOLO después de que `phase-03-validacion-prod-like.md` exista con evidencia adjunta.

---

## Contratos

Esta fase no toca `rideglory-api`. La Fase 2 (backend) ya propagó `sentry-trace`/`baggage`. No hay endpoints nuevos ni modificados.

**Dependencia dura:** el criterio 5 del PRD (traza correlacionada) y el criterio 12 (evidencia prod-like) requieren que el gateway ya esté desplegado con propagación de `sentry-trace`. Verificar antes de emitir el PR final.

---

## Datos / Migraciones

No hay cambios de base de datos. No aplica `MIGRATION_PLAN.md`.

---

## Env

Ver `docs/exec-runs/observability-sentry/analysis/ENV_DELTA.md` (archivo separado — actualizado rev 2).

Resumen actualizado (D4 rev 2):

| Variable | Flavor | Valor | Cómo se inyecta |
|----------|--------|-------|-----------------|
| `SENTRY_DSN` | dev | `""` (vacío) | `config/dev.json` → `--dart-define-from-file` → `const String.fromEnvironment('SENTRY_DSN', defaultValue: '')` |
| `SENTRY_DSN` | prod | DSN real de Sentry | `config/prod.json` → idem |
| `SENTRY_AUTH_TOKEN` | CI only | Token de API Sentry | GitHub Secret → workflow |
| `SENTRY_ORG` | CI only | Org slug de Sentry | GitHub Secret → workflow |
| `SENTRY_PROJECT` | CI only | Project slug de Sentry | GitHub Secret → workflow |

`SENTRY_DEV_VERIFY` es un `--dart-define` puntual para la ventana de verificación; NO va en config JSON.

**NO usar `@EnviedField` para `SENTRY_DSN`** — `envied` no ve los `--dart-define`. Solo `const String.fromEnvironment(...)`.

---

## Riesgos

| Riesgo | Probabilidad | Impacto | Mitigación |
|--------|-------------|---------|------------|
| Doble binding DI (`FirebaseCrashReporter` + `SentryCrashReporter` ambos como `CrashReporter`) durante coexistencia | Alta si no se coordinan `@Environment` | Build falla en `build_runner` | Retirar `@Injectable(as: CrashReporter)` de `FirebaseCrashReporter` al añadir Sentry |
| Crash sin cobertura si se retira Crashlytics antes de la evidencia | Media (presión de limpieza) | Alto | Guardrail G1: bloquear retiro hasta que exista `phase-03-validacion-prod-like.md` |
| `tracePropagationTargets` mal configurado → headers `sentry-trace` enviados a Mapbox/Firebase Storage | Media | PII/seguridad | Restringir a `RegExp(r'api\.rideglory\.com')` + hosts locales dev |
| `SENTRY_DSN` leído con `@EnviedField` en lugar de `String.fromEnvironment` | Alta (trampa común) | DSN siempre vacío en prod cuando se usa flavor | Usar SOLO `const String.fromEnvironment('SENTRY_DSN', defaultValue: '')` — D4 rev 2 |
| WIP del wizard de eventos mezclado en el PR de Sentry | Media | Diff contaminado, difícil de revisar | `git stash` de los 8 archivos excluidos antes del PR |
| `phase-03-validacion-prod-like.md` no creado antes del retiro de Crashlytics | Media | Sin evidencia prod, retiro prematuro | Criterio 12 es bloqueante; QA verifica existencia del archivo |
| `kSentryDevVerify` no revertido antes del PR final | Baja | Dev recibe datos en Sentry | Checklist explícito en `architect-for-qa.md` |
| dSYM upload falla silenciosamente en CI (iOS) | Media | Crashes sin simbolizar en prod | Añadir `--strict` al Sentry CLI en workflow |
| `build_runner` falla post-cambio de anotaciones DI | Baja | Bloqueante | Ejecutar `dart run build_runner rebuild --delete-conflicting-outputs` |

---

## Orden de implementación

1. **ENV_DELTA**: Añadir `SENTRY_DSN` a `config/dev.json`, `config/prod.json` y sus `.example`. Verificar que `--dart-define-from-file` lo expone correctamente.
2. **Observability base**: Crear `lib/core/observability/pii_denylist.dart`.
3. **SentryCrashReporter**: Crear `lib/core/services/crash/sentry_crash_reporter.dart` con `@Environment('prod')`.
4. **NoOpCrashReporter DI**: Añadir anotaciones `@injectable @Environment('dev') @Environment('test')` a `no_op_crash_reporter.dart`.
5. **DI gating**: Modificar `lib/core/di/injection.dart` para aceptar `environment`. Retirar `@Injectable(as: CrashReporter)` de `firebase_crash_reporter.dart` (mantener la clase temporalmente). Regen `build_runner`.
6. **firebase_module.dart**: Retirar provider `FirebaseCrashlytics`; retirar parámetro `crashlytics` del provider `dio`.
7. **AppDio**: Añadir `dio.addSentry(...)` como último interceptor.
8. **main.dart**: `SentryFlutter.init` + derivación de environment + `beforeSend` gating + `const String.fromEnvironment('SENTRY_DSN')`.
9. **Tests**: `sentry_crash_reporter_test.dart` + `pii_denylist_test.dart`.
10. **CI**: Añadir secrets Sentry al workflow; paso upload dSYM/mapping.
11. **Evidencia prod-like**: Generar `phase-03-validacion-prod-like.md` con crash + 5xx simbolizados y traceId correlacionado. **Bloqueante para el paso 12.**
12. **Retiro Crashlytics** (post-evidencia): Eliminar `firebase_crash_reporter.dart`; limpiar `pubspec.yaml`, `build.gradle.kts`, `settings.gradle.kts`, `project.pbxproj`.
13. **Reversión ventana dev**: Retirar `kSentryDevVerify`; confirmar `beforeSend → null` en debug antes del PR final.

---

## Superficie de regresión

- `lib/core/di/injection.dart` y `injection.config.dart`: cualquier Cubit o Service registrado en DI puede verse afectado si el environment filter excluye incorrectamente un binding. Riesgo de `StateError: getIt<CrashReporter>()` no registrado en dev.
- `lib/main.dart`: el `runZonedGuarded` tiene múltiples await; un error de orden en `SentryFlutter.init` puede silenciar excepciones de arranque.
- `lib/core/http/app_dio.dart`: el interceptor Sentry debe ser el último; si se inserta antes del `LogInterceptor`, el log puede ver datos ya mutados.
- `android/app/build.gradle.kts` y `settings.gradle.kts`: retirar el plugin Crashlytics romperá la build si queda alguna referencia nativa al SDK.
- `ios/Runner.xcodeproj/project.pbxproj`: el build phase Crashlytics debe eliminarse junto con el retiro del pod.
- Tests existentes en `test/features/events/presentation/form/cubit/event_form_cubit_analytics_test.dart` que mockean `CrashReporter` deben seguir compilando; la interfaz no cambia.

---

## Fuera de alcance

- Cambios en `rideglory-api` (Fase 2 ya completada).
- `SentryNavigatorObserver`, screen_view, Insights/taps (Fase 4).
- Tracing del canal WebSocket `/tracking/ws`.
- Migración histórico Crashlytics → Sentry.
- Nuevas pantallas o copy visible.
- WIP del wizard de eventos (`steps/**`, `screens/**`) — ver D12.
