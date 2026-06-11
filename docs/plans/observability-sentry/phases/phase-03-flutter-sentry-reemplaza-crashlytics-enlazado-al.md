# Fase 3 — Flutter: Sentry reemplaza Crashlytics, enlazado al backend

- **Generado (UTC):** 2026-06-10T22:29:51Z
- **Slug:** observability-sentry · **Fase:** 3 · **dependsOn:** [2]
- **Nivel rg-exec recomendado:** full
- **Repos:** Flutter `/Users/cami/Developer/Personal/Rideglory` (esta fase NO toca `rideglory-api`)

## Objetivo

Los crashes y los errores de red de la app llegan a Sentry **solo en prod**, enlazados a la traza del backend por `sentry-trace`/`baggage`, **sin doble reporte, sin fuga de PII y sin ninguna ventana sin cobertura de crashes**. La migración mantiene la interface `CrashReporter` como único punto de acoplamiento; el comportamiento visible de errores no cambia (mensajes siguen en español desde `rest_client_functions.dart`, el `traceId` nunca es copy visible).

## Alcance (entra / no entra)

**Entra:**
- Añadir `sentry_flutter` + `sentry_dio` a `pubspec.yaml`.
- Nueva impl `SentryCrashReporter implements CrashReporter`, gateada por DI (`@Environment('prod')`); `NoOpCrashReporter` registrado y activo en debug/test (`@Environment('dev')` + `@Environment('test')`).
- Gating de DI: `configureDependencies()` deriva el environment (vía `kReleaseMode`/flavor) y lo pasa a `getIt.init(environment: ...)`; call site actualizado en `main.dart`.
- `SentryFlutter.init` gated en `main.dart` (DSN vacío en dev → no envía; `beforeSend → null` en debug; `environment` por flavor).
- Denylist PII propia de Flutter en `lib/core/observability/pii_denylist.dart`, referenciada desde `beforeSend`/`beforeBreadcrumb`.
- `dio.addSentry()` al final de la cadena de interceptors de `AppDio.create`, con `tracePropagationTargets` restringido al host de la API Rideglory.
- Mapeo de `NetworkErrorClassification` → `level`/`fingerprint`/filtrado: los 5xx/crashes van como *error events* (alerta); los 4xx de negocio y las `FirebaseAuthException` esperadas **no** se reportan como *error event* sino como **breadcrumb / Sentry log** (contexto ligado al trace, sin alerta ni consumo de la cuota de errores) — coherente con el tratamiento de 4xx del backend (Fase 2).
- Retiro de Crashlytics **solo después** de validar Sentry: `pubspec.yaml`, `firebase_module.dart` (incluido el provider `dio(...)` y su `setCustomKey('api_base_url')`), piezas nativas iOS/Android.
- Reemplazo de `crashlytics.setCustomKey('api_base_url', ...)` por tag/scope de Sentry.
- Test de gating debug/prod (Sentry no inicializa ni reporta en debug/test; `NoOpCrashReporter` activo) y test de que la denylist redacta.
- Subtarea DevOps: upload de dSYM (iOS) y mapping ProGuard (Android) en CI.

**No entra:**
- Cambios de backend (`rideglory-api`): la Fase 2 ya entregó la continuación de `sentry-trace` en el gateway.
- Nuevas pantallas, copy visible o cambio del flujo de errores hacia el usuario.
- Insights/taps/`screen_view`/`SentryNavigatorObserver` (eso es Fase 4).
- Tracing del canal WebSocket `/tracking/ws` (best-effort, fuera de alcance core).
- Histórico de Crashlytics (se empieza limpio en Sentry).

## Que se debe hacer (pasos concretos y ordenados)

> **Regla anti-ventana (R4):** integrar + **validar** Sentry **antes** de retirar cualquier pieza de Crashlytics. El retiro (pasos 9–10) es lo último.

> **Nota de binding (resuelve el conflicto pasos 3↔9):** para validar prod-like (paso 8) hay que correr `build_runner` y compilar **mientras Crashlytics todavía existe**. Para evitar la doble registración de `CrashReporter` (dos impls `@Injectable(as: CrashReporter)` → falla de DI), se usa el calificador `@Environment` desde el paso 3: al añadir `SentryCrashReporter` se le pone `@Environment('prod')` y **en el mismo paso** se cambia la anotación de `FirebaseCrashReporter` de `@Injectable(as: CrashReporter)` a `@Injectable(as: CrashReporter) @Environment('dev')` (temporalmente, hasta su retiro en el paso 9). Así ambas impls coexisten sin colisión durante la validación. `build_runner` (paso 4) corre **antes** del paso 8, no solo en el paso 10.

1. **Cerrar el gate de la fase** (recordatorio del PO): gestión de DSN por flavor (`config/<flavor>.json` / `--dart-define`) + upload de símbolos en CI. Sin DSN de prod resuelto, la validación del paso 8 no es posible.
2. **Deps:** añadir `sentry_flutter` y `sentry_dio` a `pubspec.yaml` (`flutter pub get`).
3. **Impl + gating DI (binding seguro):**
   - Crear `SentryCrashReporter implements CrashReporter` en `lib/core/services/crash/sentry_crash_reporter.dart`, anotada `@Injectable(as: CrashReporter) @Environment('prod')`. Delega en `Sentry.captureException(...)` mapeando `reason`/`information`/`fatal` a `level`/`fingerprint`/`contexts`. `setEnabled` controla el opt-out vía `Sentry.close()`/scope.
   - Registrar `NoOpCrashReporter` en DI con `@Injectable(as: CrashReporter) @Environment('dev') @Environment('test')` (hoy es un test double manual; pasa a estar registrado para cubrir debug/test).
   - Cambiar la anotación de `FirebaseCrashReporter` a `@Environment('dev')` **temporalmente** para que conviva durante la validación (se elimina en el paso 9).
   - Editar `lib/core/di/injection.dart`: `configureDependencies()` deriva el environment (p.ej. `final env = kReleaseMode ? Environment.prod : Environment.dev;`, con `Environment.test` cuando aplica en tests) y llama `getIt.init(environment: env)`.
   - Actualizar el call site en `lib/main.dart` (la llamada `configureDependencies()`) si la firma cambia para aceptar/derivar el environment.
4. **Code-gen:** `dart run build_runner build --delete-conflicting-outputs` para regenerar `injection.config.dart` con los `EnvironmentFilter`. (Este paso ocurre **antes** del paso 8.)
5. **Denylist PII (Flutter):** crear `lib/core/observability/pii_denylist.dart` como **constante Dart propia** (lista de claves a redactar: `authorization`, `id_token`, `password`, `email`, `phone`/teléfono, `soat`, `placa`/plate, `vin`). No es el mismo módulo del backend TypeScript: es la fuente única **del lado Flutter**, alineada en contenido con la denylist de Fase 1, pero independiente en código.
6. **Init gated:** en `lib/main.dart`, dentro del `runZonedGuarded` existente y **antes** de `runApp`, `await SentryFlutter.init((options) { ... })`:
   - `options.dsn` = DSN por flavor (vacío en dev → SDK no envía).
   - `options.environment` = flavor (`dev`/`prod`).
   - `options.beforeSend` = handler que retorna `null` en `kDebugMode` y que redacta usando `pii_denylist.dart`; aplica el mapeo de `level`/`fingerprint` derivado de la clasificación de red.
   - `options.beforeBreadcrumb` = handler que redacta usando `pii_denylist.dart`.
   - No re-enganchar `FlutterError.onError`/`PlatformDispatcher.onError` por fuera de Sentry: dejar que Sentry instale sus hooks y que `registerCrashHandlers` delegue en la interface sin duplicar (R2). Documentar la cadena handlers globales ↔ `runZonedGuarded` ↔ integración Sentry en comentario + en el doc de la corrida.
7. **Mapeo clasificación → Sentry (límite de acoplamiento, ver §Contratos):** la derivación `NetworkErrorClassification` → `SentryLevel`/`fingerprint`/`shouldReport` vive en `SentryCrashReporter`/`beforeSend` (capa que ya conoce el SDK), **no** en `network_error_classifier.dart`. El clasificador (`core/http`) permanece **libre del SDK de Sentry**: sigue exponiendo `shouldReport`/`category`/`httpStatus`/`dioType` sin importar `sentry`. No reportar 4xx de negocio ni `FirebaseAuthException` esperadas (la denylist ya existe en el clasificador).
8. **VALIDAR en prod-like (gate anti-ventana):** compilar un build con flavor prod y DSN real; provocar (a) un crash no fatal y (b) un 5xx de red; confirmar en Sentry que ambos llegan, con símbolos y con la traza enlazada al backend (`sentry-trace` continuado por el gateway de Fase 2). Adjuntar la evidencia bajo `docs/exec-runs/observability-sentry/phase-03-validacion-prod-like.md` (capturas/links del evento de crash + del 5xx con símbolos y `traceId` correlacionado). **No avanzar al paso 9 sin esta evidencia.**
9. **Retirar Crashlytics (solo tras paso 8):**
   - Eliminar `FirebaseCrashReporter` (`firebase_crash_reporter.dart`) y `firebase_crashlytics` de `pubspec.yaml`.
   - En `firebase_module.dart`: quitar el provider `FirebaseCrashlytics get firebaseCrashlytics`, y en el provider `Dio dio(...)` eliminar el parámetro `FirebaseCrashlytics crashlytics` y la línea `crashlytics.setCustomKey('api_base_url', resolvedUrl)` → reemplazar por `Sentry.configureScope((scope) => scope.setTag('api_base_url', resolvedUrl))` (o un tag equivalente sin PII).
   - Quitar el calificador `@Environment('dev')` temporal donde haya quedado redundante.
   - Retirar piezas nativas: iOS (`ios/Podfile`/`Podfile.lock`, `project.pbxproj` run-script de Crashlytics, `Info.plist` si aplica) y Android (Gradle plugin `firebase-crashlytics`, `google-services` que aplique).
10. **Re-code-gen + analyze + test:** `dart run build_runner build --delete-conflicting-outputs`, `dart analyze`, `flutter test`. Confirmar cero referencias residuales a `firebase_crashlytics` (grep).
11. **DevOps/CI:** añadir upload de dSYM (iOS) y mapping ProGuard (Android) a Sentry en el pipeline de build (subtarea explícita; sin ello los crashes de prod salen sin símbolos — R9).

## Archivos a crear/modificar (rutas reales, una linea de "que cambia")

**Crear:**
- `lib/core/services/crash/sentry_crash_reporter.dart` — impl `SentryCrashReporter implements CrashReporter`, `@Injectable(as: CrashReporter) @Environment('prod')`; mapea clasificación → `level`/`fingerprint`.
- `lib/core/observability/pii_denylist.dart` — constante Dart con las claves PII a redactar (fuente única del lado Flutter); consumida por `beforeSend`/`beforeBreadcrumb`.
- `docs/exec-runs/observability-sentry/phase-03-validacion-prod-like.md` — evidencia del crash + 5xx con símbolos y traza correlacionada (criterio 12).
- `test/core/services/crash/sentry_crash_reporter_test.dart` — gating debug/prod + mapeo nivel/fingerprint + filtrado 4xx.
- `test/core/observability/pii_denylist_test.dart` — falla si una clave PII aparece sin redactar.

**Modificar:**
- `pubspec.yaml` — añadir `sentry_flutter`/`sentry_dio`; (paso 9) quitar `firebase_crashlytics`.
- `lib/main.dart` — `SentryFlutter.init` gated dentro de `runZonedGuarded`; ajustar call site de `configureDependencies()` al environment.
- `lib/core/di/injection.dart` — `configureDependencies()` deriva el environment (`kReleaseMode`/flavor) y lo pasa a `getIt.init(environment: ...)`.
- `lib/core/di/firebase_module.dart` — (paso 9) quitar provider `FirebaseCrashlytics` y la dependencia/`setCustomKey` del provider `dio(...)`; reemplazar por tag de Sentry.
- `lib/core/http/app_dio.dart` — `dio.addSentry()` al final de la cadena con `tracePropagationTargets` = host de la API Rideglory.
- `lib/core/services/crash/firebase_crash_reporter.dart` — paso 3: anotar `@Environment('dev')` temporal; paso 9: eliminar el archivo.
- `lib/core/services/crash/no_op_crash_reporter.dart` — registrar en DI con `@Injectable(as: CrashReporter) @Environment('dev') @Environment('test')`.
- `config/dev.json` / `config/prod.json` (+ `.example`) — clave `SENTRY_DSN` por flavor (vacía en dev).
- `ios/Podfile`, `ios/Podfile.lock`, `ios/Runner.xcodeproj/project.pbxproj`, `ios/Runner/Info.plist` — retiro nativo Crashlytics + config dSYM upload.
- Gradle Android (`android/app/build.gradle` / `android/build.gradle`) — retiro plugin `firebase-crashlytics` + config mapping ProGuard upload.
- CI workflow de build (GitHub Actions) — paso de upload de símbolos a Sentry.
- `docs/features/authentication.md` y/o docs de observabilidad del feature afectado — reflejar el cambio Crashlytics→Sentry si documenta comportamiento.

> Nota: `lib/core/http/network_error_classifier.dart` **NO** se modifica para importar Sentry (ver paso 7). Se mantiene libre del SDK.

## Contratos / API rideglory-api (o "ninguno")

**Ninguno nuevo en esta fase.** Esta fase **consume** el contrato aditivo entregado por la Fase 2: el gateway continúa el `sentry-trace`/`baggage` que el `sentry_dio` adjunta a las requests hacia el host de la API (gracias a `tracePropagationTargets`), cerrando el trace móvil→gateway→MS. No se añade ni cambia ningún endpoint, DTO ni message pattern. El header `x-trace-id` que devuelve el gateway sigue siendo metadato técnico (tag/breadcrumb), nunca copy visible.

**Límite de acoplamiento (Clean Architecture):** `network_error_classifier.dart` (capa `core/http`) NO importa `package:sentry`. La traducción a tipos del SDK (`SentryLevel`, `fingerprint`) ocurre en `SentryCrashReporter`/`beforeSend`. Si en la implementación se considerara importar `SentryLevel` en el clasificador, se prefiere explícitamente **no** hacerlo: el clasificador devuelve datos puros (`shouldReport`/`category`/`httpStatus`) y el adaptador Sentry los mapea. Esto preserva domain/core libres del SDK de terceros.

## Cambios de datos / migraciones (o "ninguno")

Ninguno. La observabilidad no toca esquema de datos ni Prisma. No hay code-gen de DTO/freezed; el único code-gen es DI (`build_runner` regenera `injection.config.dart` por las nuevas anotaciones `@Injectable`/`@Environment`).

## Criterios de aceptacion (numerados, observables, testeables)

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
12. **Evidencia de validación prod-like:** existe `docs/exec-runs/observability-sentry/phase-03-validacion-prod-like.md` con la prueba del crash no fatal + del 5xx, ambos con símbolos legibles y `traceId` correlacionado al backend; el retiro de Crashlytics (paso 9) ocurrió **después** de adjuntar esa evidencia.

## Pruebas (unitarias/widget/integracion)

- **Unitaria — gating DI** (`test/core/services/crash/sentry_crash_reporter_test.dart`): con environment `test`/`dev`, `getIt<CrashReporter>()` es `NoOpCrashReporter`; verificar que un `recordError` no contacta el SDK. (Criterios 2, 3, 9.)
- **Unitaria — mapeo clasificación→Sentry:** dado un `NetworkErrorClassification` con `shouldReport=false` (4xx de negocio / `FirebaseAuthException` esperada) el adaptador no produce evento; con `shouldReport=true` produce `level`/`fingerprint` esperados. (Criterios 5, 7.)
- **Unitaria — denylist PII** (`test/core/observability/pii_denylist_test.dart`): construir un evento/breadcrumb con cada clave PII y aseverar que `beforeSend`/`beforeBreadcrumb` la redactan; el test falla si una clave queda en claro. (Criterio 6.)
- **Estática/grep en CI o test:** `firebase_crashlytics` no aparece en `lib/` ni `pubspec.yaml`; `network_error_classifier.dart` no importa `sentry`. (Criterios 1, 7.)
- **Manual prod-like** (no automatizable): crash no fatal + 5xx con símbolos y traza; evidencia en `docs/exec-runs/observability-sentry/phase-03-validacion-prod-like.md`. (Criterios 11, 12.)

## Riesgos y mitigaciones

- **R2 — Doble reporte** (FlutterError + PlatformDispatcher + handlers Sentry + `runZonedGuarded`): dejar que Sentry instale sus hooks y que `registerCrashHandlers` delegue en la interface sin re-enganchar; test de gating que cuenta = 1.
- **R3 — Fuga de PII/secretos:** `pii_denylist.dart` central del lado Flutter + `beforeSend`/`beforeBreadcrumb`; test que falla si una clave queda sin redactar; revisión explícita antes de habilitar prod.
- **R4 — Ventana sin reporte de crashes:** secuencia estricta integrar+validar Sentry (paso 8 con evidencia) → recién retirar Crashlytics (paso 9). `build_runner` corre antes del paso 8.
- **Binding doble de `CrashReporter`** (pasos 3↔9): calificar ambas impls con `@Environment` distintos desde el paso 3 (Sentry=`prod`, Firebase=`dev` temporal) para que coexistan sin colisión durante la validación; eliminar Firebase en el paso 9.
- **R9 — Símbolos ilegibles:** upload de dSYM/ProGuard en CI como subtarea DevOps explícita.
- **Cambios nativos difíciles de revertir** (Podfile/pbxproj/Gradle/Info.plist): retirarlos **al final**, con build verde antes y después; sin usuarios reales el retiro agresivo es aceptable si los tests pasan.
- **`tracePropagationTargets` mal restringido** → fuga de `sentry-trace` a terceros: limitar al host de la API Rideglory; verificar en el build prod-like.

## Dependencias (fases prerequisito y por que)

- **Fase 2 (dura):** el enlace móvil→backend solo cierra si el gateway ya continúa el `sentry-trace`/`baggage` que esta fase propaga vía `sentry_dio` + `tracePropagationTargets`. Sin Fase 2, el criterio 5 (traza correlacionada) y la evidencia del criterio 12 no son verificables.
- **Fase 1 (transitiva):** provee el `traceId` end-to-end y la denylist PII de backend que esta fase espeja (en contenido, no en código) en `pii_denylist.dart`.
- **Gate de fase (PO):** cerrar gestión de DSN por flavor + upload de símbolos en CI antes de abrir el `rg-exec`.

## Ejecucion recomendada (nivel rg-exec: full)

Por qué ese nivel: Cambios nativos iOS/Android (Podfile, project.pbxproj, Gradle, Info.plist) difíciles de revertir, retiro de crash reporting con riesgo de ventana sin cobertura, denylist PII central, doble reporte con runZonedGuarded, DSN por flavor y upload de símbolos en CI. Alto roce de build/config + seguridad. Requiere el trace móvil->backend de la Fase 2 para cerrar la correlación.
