> Slim handoff — read this before handoffs/architect.md

# Architect → Frontend (Flutter)

**Feature path:** `lib/core/` (no feature layer; esto es infraestructura core)
**Rev:** 2 (correcciones Auditor Opus)

## Paquetes nuevos en pubspec.yaml

```yaml
sentry_flutter: ^8.x    # SDK principal + FlutterError hooks
sentry_dio: ^8.x        # Interceptor Dio para propagación sentry-trace
```

Tras validación prod-like, **eliminar**:
```yaml
firebase_crashlytics: ^5.2.0
```

## Archivos a crear

### `lib/core/observability/pii_denylist.dart`
```dart
/// Claves prohibidas en eventos y breadcrumbs Sentry.
const Set<String> kPiiDenylist = {
  'authorization', 'id_token', 'password', 'email',
  'phone', 'telefono', 'soat', 'placa', 'vin',
};
```

### `lib/core/services/crash/sentry_crash_reporter.dart`
- `@Injectable(as: CrashReporter) @Environment('prod')`
- Constructor: sin inyección (Sentry es un singleton global, no se inyecta)
- `recordError` → `Sentry.captureException` con scope que setea tags desde `information`
- `setEnabled` → no-op (Sentry se gatea en `beforeSend` / DSN vacío)
- NO importar `package:sentry` en ningún otro archivo (grep CI verifica esto)
- `NetworkErrorClassification.shouldReport = false` → no llamar `Sentry.captureException`; el mapeo 5xx→`SentryLevel.error` / timeout→`SentryLevel.warning` vive aquí

## Archivos a modificar

### `lib/core/services/crash/no_op_crash_reporter.dart`
Añadir al principio de la clase:
```dart
@injectable
@Environment('dev')
@Environment('test')
```

### `lib/core/di/injection.dart`
```dart
void configureDependencies({String environment = 'dev'}) {
  // ...
  getIt.init(environment: environment);
}
```

### `lib/main.dart` (orden dentro de runZonedGuarded)
1. `await Firebase.initializeApp(...)` — ya existe
2. `configureDependencies(environment: kReleaseMode ? 'prod' : 'dev')`
3. `await SentryFlutter.init((options) { ... })` — nuevo
4. `registerCrashHandlers(...)` — ya existe
5. `runApp(...)` — ya existe

**IMPORTANTE (D4 rev 2):** El DSN se lee con `String.fromEnvironment`, NO con `AppEnv.sentryDsn`:

```dart
// Constantes al inicio de main.dart (fuera de runZonedGuarded):
const String _sentryDsn = String.fromEnvironment('SENTRY_DSN', defaultValue: '');
const bool kSentryDevVerify = bool.fromEnvironment('SENTRY_DEV_VERIFY');

// Dentro de runZonedGuarded:
await SentryFlutter.init((options) {
  options.dsn = _sentryDsn;  // vacío en dev → Sentry no envía nada
  options.environment = kReleaseMode ? 'prod' : 'dev';
  options.beforeSend = (event, hint) {
    if (kDebugMode && !kSentryDevVerify) return null;
    return _scrubPii(event);
  };
  options.beforeBreadcrumb = (crumb) => _scrubPiiBreadcrumb(crumb);
  options.tracesSampleRate = kReleaseMode ? 0.2 : 0.0;
});
```

**NO declarar `sentryDsn` en `app_env.dart` como `@EnviedField`** — `envied` no lee `--dart-define`, solo el archivo `.env` en tiempo de generación. El DSN quedaría siempre vacío en prod con ese mecanismo.

### `lib/core/di/firebase_module.dart`
- Eliminar `@lazySingleton FirebaseCrashlytics get firebaseCrashlytics`
- Eliminar parámetro `FirebaseCrashlytics crashlytics` del provider `dio`
- Eliminar la línea `crashlytics.setCustomKey('api_base_url', resolvedUrl)`
- El tag `api_base_url` se setea en scope Sentry dentro de `SentryFlutter.init` o en `AppDio.create`

### `lib/core/http/app_dio.dart`
```dart
import 'package:sentry_dio/sentry_dio.dart';
// ...
// Último interceptor (después del LogInterceptor):
dio.addSentry(
  captureFailedRequests: true,
  tracePropagationTargets: [RegExp(r'api\.rideglory\.com|10\.0\.2\.2|localhost')],
);
```

## Archivos a eliminar (tras validación prod-like)

- `lib/core/services/crash/firebase_crash_reporter.dart`

## Archivos EXCLUIDOS del scope de esta fase

Los siguientes archivos tienen cambios en el working tree (WIP wizard de eventos) pero NO pertenecen a observability-sentry. Hacer `git stash` antes del PR:
- `lib/features/events/presentation/form/widgets/steps/navigation_row.dart`
- `lib/features/events/presentation/form/widgets/steps/publish_row.dart`
- `lib/features/events/presentation/form/widgets/steps/review_card.dart`
- `lib/features/events/presentation/form/widgets/steps/review_row.dart`
- `lib/features/events/presentation/form/widgets/steps/step_circle.dart`
- `lib/features/events/presentation/form/screens/route_cta_bar.dart`
- `lib/features/events/presentation/form/screens/route_map_area.dart`
- `lib/features/events/presentation/form/screens/route_search_bar.dart`

## DI environment derivation

```dart
// En main.dart, antes de llamar configureDependencies:
final diEnvironment = kReleaseMode ? 'prod' : 'dev';
configureDependencies(environment: diEnvironment);
```

## Tests a crear

- `test/core/services/crash/sentry_crash_reporter_test.dart` — usar `SentryFlutter.init` con `FakeSentry`; verificar 1 evento por 5xx, 0 eventos por 4xx, PII redactado
- `test/core/observability/pii_denylist_test.dart` — verificar que cada clave de `kPiiDenylist` sea detectada

## Guardrails críticos

- `network_error_classifier.dart` NUNCA importa `package:sentry` (grep CI)
- `tracePropagationTargets` NUNCA incluye `mapbox` ni `firebasestorage`
- `kSentryDevVerify` DEBE revertirse antes del PR final
- NO usar `AppEnv.sentryDsn` — usar `const String.fromEnvironment('SENTRY_DSN', defaultValue: '')`
- `phase-03-validacion-prod-like.md` debe existir ANTES de eliminar `firebase_crash_reporter.dart`

> Full detail: handoffs/architect.md
