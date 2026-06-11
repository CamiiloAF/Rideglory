# 01 — System Scan — observability-sentry

- **Generado (UTC):** 2026-06-10T22:07:07Z
- **Lente:** `00-intake.md` (observabilidad unificada Sentry + logging estructurado + insights)
- **Repos:** Flutter `/Users/cami/Developer/Personal/Rideglory` + backend `/Users/cami/Developer/Personal/rideglory-api`

## Inventario Flutter

### Núcleo de crash/observabilidad (`lib/core/services/crash/`)
- `crash_reporter.dart` — interface `CrashReporter` (Dart puro): `recordError(...)`, `setEnabled(bool)`. Ya documenta límites no-PII / GA4. **Reutilizable para `SentryCrashReporter`.**
- `firebase_crash_reporter.dart` — impl actual sobre Crashlytics (a reemplazar).
- `no_op_crash_reporter.dart` — impl nula (gating debug/test).
- `crash_handler_setup.dart` — `registerCrashHandlers({isDebug, reporter})`: engancha `FlutterError.onError` + `PlatformDispatcher.instance.onError`; no registra en debug. Aislado de `main.dart`.

### Init (`lib/main.dart`)
- `runZonedGuarded` envuelve toda la init + `runApp`; `getIt<CrashReporter>().setEnabled(!kDebugMode)`, `AnalyticsService.setEnabled(!kDebugMode)`, `registerCrashHandlers(...)`, y captura de zona → `recordError(..., fatal:false)`. **Punto de inserción de `SentryFlutter.init` + revisión de doble reporte.**

### HTTP (`lib/core/http/`)
- `app_dio.dart` — `AppDio.create(...)`; interceptors: `FirebaseAuthInterceptor` + `LogInterceptor` (solo debug). **Aquí va `dio.addSentry()` al final.**
- `network_error_classifier.dart` — `NetworkErrorClassification` (shouldReport/category/reason/httpStatus/dioType) + denylist de `FirebaseAuthException` esperadas. **Matriz G5 a mapear a level/fingerprint/filtrado Sentry.**
- `firebase_auth_interceptor.dart`, `rest_client_functions.dart` (`executeService` → `Either<DomainException, T>`), `api_base_url_resolver.dart`, `api_routes.dart`.

### Analytics (`lib/core/services/analytics/`)
- `analytics_service.dart` — interface: `logEvent`, `logScreenView`, `setUserId`, `setUserProperty`, `setEnabled` (varias ya declaradas como no-op pendientes de impl).
- `firebase_analytics_service.dart`, `analytics_events.dart` (~61 constantes de evento), `analytics_params.dart`, `analytics_screen_names.dart`, `analytics_uid_hasher.dart`.
- `lib/shared/router/analytics_route_observer.dart` — observer de `screen_view` (convivirá con `SentryNavigatorObserver`).
- `lib/features/profile/presentation/cubits/analytics_consent_cubit.dart` + `profile_analytics_optout_tile.dart` — opt-out de usuario.

### DI (`lib/core/di/firebase_module.dart`)
- Provee `FirebaseAnalytics`, `FirebaseCrashlytics`, `FirebaseRemoteConfig`, `Dio`. El provider `dio(...)` recibe `FirebaseCrashlytics` y hace `crashlytics.setCustomKey('api_base_url', ...)`. **Esta dependencia a Crashlytics debe removerse/migrarse.**

### Features (`lib/features/`)
13 features con capas domain/data/presentation: `authentication`, `events`, `event_registration`, `vehicles`, `vehicle_documents`, `maintenance`, `soat`, `tecnomecanica`, `users`, `profile`, `home`, `notifications`, `splash`. Candidatos a breadcrumbs/eventos clave: `authentication` (login/submit), `events` (creación/lectura), `event_registration` (embudo).

## Dependencias (pubspec.yaml)
- `firebase_crashlytics: ^5.2.0` — **a retirar.**
- `firebase_analytics: ^12.0.0` — se expande (insights).
- `firebase_core: ^4.2.1`, `firebase_remote_config: ^6.4.0`.
- `dio: ^5.9.2`, `retrofit: ^4.9.2` — soportan `sentry_dio`.
- `flutter_bloc / bloc`, `injectable`, `freezed` (stack estándar).
- **Falta:** `sentry_flutter`, `sentry_dio` (a añadir).

## Superficie rideglory-api

### Microservicios (TCP) + gateway (HTTP)
- **api-gateway** (HTTP, prefix `/api`, `WsAdapter`) — único punto HTTP. `main.ts`: `RpcCustomExceptionFilter` global, `ValidationPipe`. Comunica con MS vía `ClientProxy.send('pattern', payload)`.
- **MS TCP:** `users-ms`, `events-ms`, `vehicles-ms`, `maintenances-ms`, `notifications-ms`. Cada `main.ts`: `createMicroservice(TCP)` + `RpcAllExceptionsFilter` (de `@rideglory/common-lib`) + `ValidationPipe`.
- `rideglory-common-lib` (filtros compartidos), `rideglory-contracts` (DTOs/patterns), `dashboard`, `terraform`, `docker-compose.yml`.

### Grupos de endpoints en gateway (controllers)
- `vehicles` (14), `registrations` (9), `events` (8), `tracking-http` (6), `maintenances` (4), `notifications` (4), `users` (4), `places` (3), `ai` (2), `home` (1), `health` (1). Total ~56 endpoints HTTP.

### Logging / errores actuales
- `api-gateway/src/common/middleware/http-logger.middleware.ts` — `HttpLoggerMiddleware` con `Logger('HTTP')`: loguea `método url status ms — ip` en `res.on('finish')`; nivel por status (≥500 error, ≥400 warn). **Base a sustituir por nestjs-pino + traceId.**
- `RpcCustomExceptionFilter` (gateway) — normaliza `RpcException`/`HttpException`; **solo loguea `.error` si status ≥500**; responde `{statusCode, message}` (sin traceId). **Punto de Sentry + log 4xx + traceId al cliente.**
- `RpcAllExceptionsFilter` (common-lib) — filtro RPC de los MS; loguea y re-lanza como `RpcException`. **Punto de `@SentryExceptionCaptured()` por MS.**

### Config (joi `envs.ts`)
Los 6 servicios tienen `config/envs.ts` con joi. El de gateway **no** incluye `NODE_ENV` ni `SENTRY_DSN`. **Hay que añadir ambos a los 6.**

### Tracing existente
Grep no encontró `traceId`/`correlationId`/`sentry-trace`/`x-request-id` en `src`. **Greenfield total: no hay correlación de requests hoy.**

## Gap analysis (vs. objetivo)

| Capacidad | Estado | Falta |
|---|---|---|
| Interface `CrashReporter` desacoplada (Flutter) | **implemented** | Solo nueva impl Sentry |
| Handlers globales + runZonedGuarded | **implemented** | Revisar doble reporte al integrar Sentry |
| Clasificación de errores de red (matriz G5) | **partial** | Mapear a `level`/`fingerprint`/filtrado Sentry; no reportar 4xx negocio |
| Crashlytics → Sentry (Flutter) | **not started** | `sentry_flutter`+`sentry_dio` deps, `SentryFlutter.init`, retiro Crashlytics (pubspec + `firebase_module` + nativo iOS/Android), gating dev/prod por flavor |
| `dio.addSentry()` + `tracePropagationTargets` | **not started** | Interceptor Sentry en `AppDio`, restringir a API Rideglory |
| Logging estructurado backend (pino) | **not started** | `nestjs-pino` + `pino-pretty` dev / JSON prod; reemplazar `HttpLoggerMiddleware` |
| Logging req/resp con redacción PII + traceId | **partial** | Existe middleware básico sin redacción ni traceId; falta allowlist/denylist |
| traceId/correlationId (generar+propagar HTTP+TCP+cliente) | **not started** | Greenfield; decidir shape del payload TCP (`{data, meta:{traceId}}`) — coordinar `@rideglory/contracts` |
| Sentry backend (instrument.ts + SentryModule + filtros) | **not started** | Por los 6 servicios; gating `NODE_ENV==='production'`; tag `service` o proyecto-por-servicio |
| `NODE_ENV` + `SENTRY_DSN` en joi | **not started** | Añadir a los 6 `envs.ts` |
| Log 4xx (hoy solo ≥500) + traceId al cliente | **not started** | Modificar `RpcCustomExceptionFilter` |
| Tracing distribuido móvil→gateway→MS | **not started** | Continuar `sentry-trace` de Flutter en gateway y propagar por TCP |
| Firebase Analytics expandido (taps, screen_view, drop-off) | **partial** | ~61 eventos + opt-out + route observer ya existen; faltan taps de botones clave, drop-off por step, catálogo y docs de eventos |

## Patrones (del codebase, a respetar)
- **Flutter:** Clean Architecture (domain Dart-puro / data sin BuildContext / presentation sin HTTP); Cubit+`ResultState<T>`; DI `injectable`+`get_it`; la interface `CrashReporter`/`AnalyticsService` ya es Dart puro → la impl Sentry vive en `data`/`core/services` y se registra por `@Injectable(as: CrashReporter)`.
- **Backend:** NestJS gateway HTTP + MS TCP; filtros de excepción centralizados (gateway + common-lib); config validada con joi por servicio; comunicación `ClientProxy.send(pattern, payload)`.
- **Privacidad (regla de oro):** dev→consola, prod→Sentry; nunca PII/secretos. Denylist confirmada por el intake: Authorization, ID token, password, email, teléfono, SOAT, placa, VIN.

## Implicaciones para el plan
- Las **interfaces ya existen** (`CrashReporter`, `AnalyticsService`): la migración Flutter es de implementación + init + deps + retiro de Crashlytics (incl. piezas nativas iOS/Android) — bajo riesgo arquitectónico, alto en config/build (DSN por flavor, `--dart-define`/`config/<flavor>.json`).
- El **mayor esfuerzo greenfield es el traceId end-to-end**: no existe correlación hoy y propagar por TCP toca el shape de los message patterns en `@rideglory/contracts` (gotcha de rebuild de contracts en memoria). Decidir wrapper `{data, meta:{traceId}}` vs. mecanismo menos invasivo es la decisión arquitectónica crítica (Pregunta abierta #4).
- **6 servicios** comparten el patrón (1 gateway + 5 MS): instrument.ts + SentryModule + joi `NODE_ENV/SENTRY_DSN` se replica ×6 → candidato a abstracción en `rideglory-common-lib`. Decidir proyecto-Sentry-por-servicio vs. compartido con tag `service` (Pregunta #1) condiciona la cuota free (5k/mes, Pregunta #2).
- **Insights está parcialmente hecho** (~61 eventos, opt-out, route observer): la Fase 4 es incremental (taps, drop-off por step, `SentryNavigatorObserver`+GA4, catálogo+docs), no fundacional.
- Las **4 fases del intake mapean limpio** al gap (1 backend logging+traceId, 2 backend Sentry+tracing, 3 Flutter Sentry, 4 insights); la Fase 1 (traceId+pino) es prerequisito de la 2 y de la 3 (tracing distribuido). Sin artefactos de diseño UI relevantes (`docs/design/html-mockups` no toca observabilidad); feature sin UI nueva salvo, quizá, el tile de opt-out ya existente.
