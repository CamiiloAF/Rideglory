> Slim handoff — read this before handoffs/architect.md

# Architect → QA

**Rev:** 2 (correcciones Auditor Opus)

## Comandos de verificación

```bash
# Análisis estático (debe pasar sin errores nuevos)
dart analyze

# Tests (todos en verde antes y después del retiro de Crashlytics)
flutter test

# Verificar que network_error_classifier.dart no importa sentry (G4)
grep -r 'package:sentry' lib/core/http/network_error_classifier.dart && echo "VIOLACION G4" || echo "OK"

# Verificar que firebase_crashlytics ya no aparece en lib/ tras el retiro
grep -r 'firebase_crashlytics\|FirebaseCrashlytics' lib/ && echo "PENDIENTE RETIRO" || echo "OK"

# Verificar que tracePropagationTargets no incluye terceros
grep -r 'mapbox\|firebasestorage\|googleapis' lib/core/http/app_dio.dart && echo "VIOLACION G5" || echo "OK"

# Verificar que SENTRY_DSN NO usa @EnviedField (D4 rev 2)
grep 'sentryDsn\|SENTRY_DSN' lib/core/config/app_env.dart && echo "VIOLACION D4: usar String.fromEnvironment en main.dart" || echo "OK"

# Verificar que los archivos del wizard de eventos NO están en el diff de esta fase
git diff --name-only | grep 'form/widgets/steps\|form/screens' && echo "SCOPE VIOLATION: WIP wizard mezclado" || echo "OK"

# Verificar que phase-03-validacion-prod-like.md existe antes de retiro Crashlytics
ls docs/exec-runs/observability-sentry/phase-03-validacion-prod-like.md && echo "EVIDENCIA PRESENTE — retiro autorizado" || echo "BLOQUEANTE: falta evidencia prod-like"
```

## Criterios de aceptación — traceabilidad

| CA PRD | Qué verificar | Cómo |
|--------|--------------|------|
| CA1 | `sentry_flutter` y `sentry_dio` en `pubspec.yaml`; `firebase_crashlytics` ausente tras retiro | `grep` en pubspec |
| CA2 | `SentryCrashReporter @Environment('prod')`, `NoOpCrashReporter @Environment('dev','test')`, `configureDependencies(environment)` actualizado | Leer anotaciones + injection.config.dart generado |
| CA3 | `SentryFlutter.init` dentro de `runZonedGuarded` antes de `runApp` | Leer main.dart |
| CA4 | `dio.addSentry()` es el último interceptor; `tracePropagationTargets` restringido | Leer app_dio.dart |
| CA5 | 5xx → evento Sentry con traceId; 4xx/FirebaseAuthException → sin evento | `sentry_crash_reporter_test.dart` pasa |
| CA6 | PII no filtrada en eventos: `pii_denylist_test.dart` en verde | `flutter test test/core/observability/` |
| CA7 | `network_error_classifier.dart` sin import `package:sentry` | grep |
| CA8 | `firebase_module.dart` sin `FirebaseCrashlytics`; `api_base_url` seteado como tag Sentry | Leer firebase_module.dart |
| CA9 | 1 crash = 1 evento (no doble reporte) | Test gating en `sentry_crash_reporter_test.dart` |
| CA10 | `dart analyze` sin errores; `flutter test` en verde | CI |
| CA11 | CI incluye paso upload dSYM (iOS) y mapping (Android) | Leer ci.yml |
| CA12 | `phase-03-validacion-prod-like.md` con evidencia crash + 5xx simbolizados con traceId | Archivo existe y tiene contenido — **bloqueante para el retiro de Crashlytics** |
| CA-D4 | DSN leído con `String.fromEnvironment('SENTRY_DSN')` en `main.dart`; NO existe `@EnviedField sentryDsn` en `app_env.dart` | grep `app_env.dart` + leer `main.dart` |
| CA-D12 | Archivos WIP wizard de eventos (`steps/**`, `screens/**`) ausentes del diff | `git diff --name-only` no incluye esos 8 archivos |

## Tests nuevos requeridos

### `test/core/services/crash/sentry_crash_reporter_test.dart`
- `recordError` con 5xx classification → 1 evento capturado
- `recordError` con 4xx classification → 0 eventos
- `recordError` con PII en information → PII redactada en el evento
- Gating: `beforeSend` retorna `null` en debug (sin `kSentryDevVerify`)

### `test/core/observability/pii_denylist_test.dart`
- Para cada clave en `kPiiDenylist`: si aparece sin redactar en un evento de prueba, el test falla
- Claves mínimas: `authorization`, `id_token`, `password`, `email`, `phone`, `soat`, `placa`, `vin`

## Tests existentes a verificar (no deben romperse)

- `test/features/events/presentation/form/cubit/event_form_cubit_analytics_test.dart` — usa mock de `CrashReporter`; la interfaz no cambia, debe seguir compilando

## Checklist de reversión (antes del PR final)

- [ ] `kSentryDevVerify` no está hardcodeado como `true` en ningún archivo
- [ ] `beforeSend` retorna `null` en `kDebugMode` (sin el `--dart-define`)
- [ ] DSN en `config/dev.json` es vacío (`""`)
- [ ] `phase-03-validacion-prod-like.md` existe con evidencia real (bloqueante)
- [ ] Los 8 archivos WIP del wizard de eventos NO están en el diff

> Full detail: handoffs/architect.md
