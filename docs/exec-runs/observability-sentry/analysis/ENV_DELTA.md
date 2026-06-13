# ENV Delta — observability-sentry (Fase 3)

**Generated:** 2026-06-12T05:08:28Z
**Rev:** 2 (corrección Auditor Opus — mecanismo SENTRY_DSN)

---

## DECISIÓN CLAVE (D4 rev 2): Una sola fuente para SENTRY_DSN

`SENTRY_DSN` se inyecta **EXCLUSIVAMENTE** via `--dart-define-from-file=config/<flavor>.json` y se lee en Dart con:

```dart
const String sentryDsn = String.fromEnvironment('SENTRY_DSN', defaultValue: '');
```

**NO se declara como `@EnviedField` en `app_env.dart`.** La razón: `envied` lee el archivo `.env` en tiempo de generación de código (`dart run build_runner build`), no los `--dart-define` en tiempo de compilación. Si se añade `sentryDsn` a `@Envied`, el campo siempre valdría `null` o vacío al correr con `--dart-define-from-file=config/prod.json` porque `envied` nunca ve ese valor. Esta es una trampa conocida del mecanismo de flavors del proyecto.

---

## Variables nuevas

| Variable | Archivos afectados | Dev value | Prod value | Mecanismo |
|----------|--------------------|-----------|------------|-----------|
| `SENTRY_DSN` | `config/dev.json`, `config/prod.json` | `""` (vacío → no envía) | DSN real del proyecto Sentry | `--dart-define-from-file` → `const String.fromEnvironment('SENTRY_DSN', defaultValue: '')` |
| `SENTRY_AUTH_TOKEN` | `.github/workflows/ci.yml` (GitHub Secret) | N/A | Token API Sentry | Solo CI; no va en archivos JSON ni .env |
| `SENTRY_ORG` | `.github/workflows/ci.yml` (GitHub Secret) | N/A | Org slug Sentry | Solo CI |
| `SENTRY_PROJECT` | `.github/workflows/ci.yml` (GitHub Secret) | N/A | Project slug Sentry | Solo CI |

## Variable temporal (ventana de verificación)

| Variable | Mecanismo | Valor | Cuándo se usa |
|----------|-----------|-------|----------------|
| `SENTRY_DEV_VERIFY` | `--dart-define=SENTRY_DEV_VERIFY=true` | `true` para habilitar envío en dev/debug | Solo durante fase de verificación; revertir antes del PR final |

En Dart: `const bool kSentryDevVerify = bool.fromEnvironment('SENTRY_DEV_VERIFY');`

## Variables sin cambio

- `MAPBOX_ACCESS_TOKEN` — sin cambio
- `LOCAL_API_BASE_URL` — sin cambio
- Todas las variables `FIREBASE_*` — sin cambio (Firebase Auth/Storage/Messaging/Analytics siguen activos; solo Crashlytics se retira)

---

## Lectura en Dart

```dart
// En main.dart (NO en app_env.dart):
const String sentryDsn = String.fromEnvironment('SENTRY_DSN', defaultValue: '');
const bool kSentryDevVerify = bool.fromEnvironment('SENTRY_DEV_VERIFY');

await SentryFlutter.init((options) {
  options.dsn = sentryDsn;  // vacío en dev → Sentry no envía nada
  options.environment = kReleaseMode ? 'prod' : 'dev';
  options.beforeSend = (event, hint) {
    if (kDebugMode && !kSentryDevVerify) return null;
    return _scrubPii(event);
  };
});
```

---

## Checklist de acciones

- [ ] Añadir `"SENTRY_DSN": ""` a `config/dev.json`
- [ ] Añadir `"SENTRY_DSN": "<obtener-de-sentry-dashboard>"` a `config/prod.json`
- [ ] Añadir `"SENTRY_DSN": ""` a `config/dev.json.example`
- [ ] Añadir `"SENTRY_DSN": "<obtener-de-sentry-dashboard>"` a `config/prod.json.example`
- [ ] **NO modificar `app_env.dart`** — `SENTRY_DSN` no es `@EnviedField`
- [ ] Añadir los tres GitHub Secrets (`SENTRY_AUTH_TOKEN`, `SENTRY_ORG`, `SENTRY_PROJECT`) al repo antes de activar el paso CI de upload
- [ ] Verificar que `flutter run --flavor prod --dart-define-from-file=config/prod.json` expone correctamente `SENTRY_DSN` con `String.fromEnvironment`
