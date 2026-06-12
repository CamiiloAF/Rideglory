# Frontend handoff — observability-sentry (Fase 3)

**Agente:** Frontend (Flutter lib/)
**Fecha:** 2026-06-12T05:26:30Z
**Status:** done

---

## Baseline

```
flutter test — 824 tests, All tests passed.
dart analyze lib/ — No issues found.
```

---

## Archivos cambiados

### Creados

| Archivo | Descripción |
|---------|-------------|
| `lib/core/observability/pii_denylist.dart` | Constante Dart pura `kPiiDenylist` con 9 claves PII prohibidas |
| `lib/core/services/crash/sentry_crash_reporter.dart` | Impl Sentry `@Injectable(as: CrashReporter) @Environment('prod')`. Contiene también `scrubPiiFromEvent` y `scrubPiiFromBreadcrumb` (funciones públicas usadas en `main.dart`) |
| `test/core/observability/pii_denylist_test.dart` | 3 tests de la denylist |
| `test/core/services/crash/sentry_crash_reporter_test.dart` | 10 tests de scrub PII (eventos + breadcrumbs) + 1 test setEnabled no-op |

### Modificados

| Archivo | Cambio |
|---------|--------|
| `pubspec.yaml` | Añadidos `sentry_flutter: ^8.13.2` y `sentry_dio: ^8.13.2` (Crashlytics permanece hasta evidencia prod-like D10) |
| `config/dev.json` | Añadida clave `SENTRY_DSN: ""` (vacío — dev no envía a Sentry) |
| `config/prod.json` | Añadida clave `SENTRY_DSN: ""` (el operador debe llenar el DSN real del dashboard) |
| `config/dev.json.example` | Añadida clave `SENTRY_DSN: ""` |
| `config/prod.json.example` | Añadida clave `SENTRY_DSN: "<obtener-de-sentry-dashboard>"` |
| `lib/core/di/injection.dart` | `configureDependencies({String environment = 'dev'})` — pasa `environment` a `getIt.init()` |
| `lib/core/di/firebase_module.dart` | Eliminado parámetro `FirebaseCrashlytics crashlytics` del provider `dio`; eliminado `crashlytics.setCustomKey(...)`. Import `api_base_url_resolver.dart` eliminado (unused). Provider `FirebaseCrashlytics` permanece hasta evidencia prod-like |
| `lib/core/services/crash/no_op_crash_reporter.dart` | Añadidas anotaciones `@injectable @Environment('dev') @Environment('test')` |
| `lib/core/services/crash/firebase_crash_reporter.dart` | Removida anotación `@Injectable(as: CrashReporter)` para evitar doble binding. La clase permanece hasta evidencia prod-like (D10) |
| `lib/core/di/injection.config.dart` | Regenerado por `build_runner`: `NoOpCrashReporter` en `{dev, test}`; `SentryCrashReporter` como `CrashReporter` en `{prod}`; `Dio` provider sin parámetro `crashlytics` |
| `lib/core/http/app_dio.dart` | Añadido `dio.addSentry(captureFailedRequests: true)` como último interceptor; `tracePropagationTargets` configurado globalmente en `SentryFlutter.init` |
| `lib/main.dart` | `SentryFlutter.init` dentro de `runZonedGuarded`; DSN via `const String.fromEnvironment('SENTRY_DSN')`; `beforeSend` retorna `null` en `kDebugMode && !kSentryDevVerify`; `beforeBreadcrumb` con firma correcta `(crumb, hint)`; `tracePropagationTargets` restringido a `api.rideglory.com`, `10.0.2.2`, `localhost`; `configureDependencies(environment: diEnvironment)` con derivación `kReleaseMode` |

---

## Pruebas nuevas

| Archivo | Tests | Descripción |
|---------|-------|-------------|
| `test/core/observability/pii_denylist_test.dart` | 3 | Verifica contenido y cardinalidad de `kPiiDenylist` |
| `test/core/services/crash/sentry_crash_reporter_test.dart` | 10 | scrubPiiFromEvent (5 casos), scrubPiiFromBreadcrumb (4 casos), setEnabled no-op (1) |

---

## Resultado final

```
flutter test — 837 tests, All tests passed. (824 baseline + 13 nuevos)
dart analyze lib/ — No issues found.
```

---

## Verificacion manual

Para verificar que Sentry recibe eventos en modo debug, correr con el flag temporal:

```bash
flutter run --flavor dev \
  --dart-define-from-file=config/dev.json \
  --dart-define=SENTRY_DEV_VERIFY=true \
  --dart-define=SENTRY_DSN=<dsn-real-de-dev-en-sentry>
```

Con ese flag activo, `beforeSend` no bloquea eventos en modo debug.
**Revertir `kSentryDevVerify` (asegurarse que `SENTRY_DEV_VERIFY` no esté en `config/dev.json`) antes del PR final.**

---

## Guardrails verificados

| Guardrail | Estado |
|-----------|--------|
| `network_error_classifier.dart` no importa `package:sentry` | OK — grep confirmado |
| `tracePropagationTargets` no incluye mapbox ni firebasestorage | OK — solo `api.rideglory.com`, `10.0.2.2`, `localhost` |
| `SENTRY_DSN` leído con `String.fromEnvironment` (no `@EnviedField`) | OK |
| `SentryCrashReporter` es el único archivo con `package:sentry_flutter` | OK — grep confirmado |
| `NoOpCrashReporter` registrado en dev/test | OK — injection.config.dart regenerado |
| `firebase_crash_reporter.dart` sin `@Injectable` (sin doble binding) | OK |

---

## Notas para QA

1. **Sentry en dev no envía nada**: con `config/dev.json` (DSN vacío), `beforeSend` bloquea en `kDebugMode`. Normal.

2. **Para prueba con Sentry activo**: usar `--dart-define=SENTRY_DEV_VERIFY=true --dart-define=SENTRY_DSN=<dsn>`. El flag está documentado como temporal (D11).

3. **Crashlytics aún activo**: `firebase_crashlytics` sigue en pubspec. No se retira hasta que `phase-03-validacion-prod-like.md` tenga evidencia real (criterio 12 del PRD, guardrail G1). Ver ese archivo para el checklist de retiro.

4. **DI environment**: en release se usa `'prod'` (→ `SentryCrashReporter`); en debug/dev se usa `'dev'` (→ `NoOpCrashReporter`). Verificar con `flutter run --release` que el binding correcto se activa.

5. **`tracePropagationTargets`**: verificar en network logs que peticiones a Mapbox y Firebase Storage NO llevan header `sentry-trace`. Solo las peticiones a `api.rideglory.com` (y hosts locales) deben propagarlo.

6. **Archivos WIP de eventos excluidos (D12)**: los 8 archivos del wizard de eventos en `lib/features/events/presentation/form/widgets/steps/` y `screens/` no forman parte de esta fase. No deben incluirse en el PR de observability-sentry.
