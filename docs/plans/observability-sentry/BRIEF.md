# Brief — Observabilidad unificada: Sentry + logging estructurado + insights de producto

**Slug:** `observability-sentry`
**Repos afectados:** Flutter (`/Users/cami/Developer/Personal/Rideglory`) + backend NestJS (`/Users/cami/Developer/Personal/rideglory-api`)
**Objetivo:** Mejorar de raíz el sistema de logs y manejo de errores de la app y del backend, con tracing distribuido móvil→backend, logging legible de requests/responses en backend, y más insights de comportamiento de usuario. En **dev nada se envía a Sentry**: todo va a consola (incluido el backend).

## Decisiones tomadas (refinadas con el usuario)

1. **Flutter — Sentry reemplaza a Firebase Crashlytics.**
   - Reutilizar la abstracción existente `CrashReporter` (`lib/core/services/crash/`): nueva impl `SentryCrashReporter` que reemplaza a `FirebaseCrashReporter`. Mantener interface pura.
   - Quitar dependencia `firebase_crashlytics` y su init/custom keys (`firebase_module.dart:32-39`).
   - `SentryFlutter.init` en `main.dart`: DSN vacío en dev (no envía), `environment` por flavor (dev/prod, config/dev.json|prod.json), `beforeSend → null` en dev como segunda palanca, `debug = isDev` para ver en consola.
   - NO duplicar handlers: `SentryFlutter.init` ya engancha `FlutterError.onError` / `PlatformDispatcher.onError` / zona. Revisar `crash_handler_setup.dart` y `runZonedGuarded` de `main.dart` para evitar doble reporte.
   - Integración Dio: `dio.addSentry()` como último paso del init de `AppDio` (`lib/core/http/app_dio.dart`). Propaga `sentry-trace`/`baggage` automáticamente.
   - `tracePropagationTargets` limitado SOLO a la API de Rideglory (no Firebase/Mapbox/Google), para no filtrar headers de trace a terceros.
   - Preservar la clasificación de errores existente (matriz G5, `network_error_classifier.dart`, anti-doble-conteo) — mapearla a `level`/`fingerprint`/filtrado de Sentry. NO reportar 4xx de negocio esperados (cuidar cuota 5k/mes del free tier).
   - Breadcrumbs en operaciones clave (auth, submit de formularios) si aporta.

2. **Backend — pino estructurado + Sentry (errores/tracing). Aquí está el mayor dolor.**
   - Estado actual: monorepo 6 servicios NestJS (api-gateway HTTP/Express + users/vehicles/events/maintenances/notifications por TCP). **Sin logging de requests/responses, sin traceId, sin Sentry, sin NODE_ENV.**
   - **Logging de requests/responses** en el gateway (interceptor/middleware): método, ruta, status, latencia, traceId. **Redactar tokens/PII** (Authorization, Firebase ID token, password, email/teléfono, datos SOAT). Allowlist de campos.
   - **pino** como logger principal (reemplaza/encapsula el `Logger` nativo de Nest). dev: `pino-pretty` legible a consola. prod: JSON estructurado. Integrar `nestjs-pino` para que el `Logger` de Nest use pino por debajo.
   - **traceId / correlationId**: generar en el gateway si no llega; propagarlo (1) al cliente en respuestas/headers, (2) **manualmente en el payload de los message patterns TCP** hacia los MS (no hay headers HTTP entre MS), (3) como tag/attribute en Sentry. Cada línea de log lleva traceId.
   - **Sentry**: patrón oficial `instrument.ts` (primera línea de cada `main.ts`, tras `dotenv/config`) + `SentryModule.forRoot()` + `SentryGlobalFilter` (o `@SentryExceptionCaptured()` en los filtros existentes `RpcCustomExceptionFilter` y `RpcAllExceptionsFilter`). `enabled: NODE_ENV==='production'` → en dev no envía nada, solo consola.
   - **Añadir `NODE_ENV` y `SENTRY_DSN`** al esquema joi de cada `config/envs.ts` (hoy no existe discriminador de entorno). Definir si un proyecto Sentry por servicio o uno compartido con tag `service` (recomendación a evaluar en planeación: por servicio para filtrado limpio).
   - Mejorar el manejo de errores: respuesta uniforme al cliente con traceId para soporte; loguear 4xx también (hoy solo ≥500 en gateway), con nivel adecuado.
   - Tracing distribuido: gateway continúa el trace que viene de Flutter (`sentry-trace`), y propaga al resto.

3. **Insights de producto — expandir Firebase Analytics (GA4) existente.**
   - Ya instrumentado (no rehacer): embudos de creación de evento (`eventsCreateStarted→draftSaved→published→publishFailed`), registro (`registrationStarted→stepAdvanced→stepBack→submitted→abandoned`), auth, lectura de eventos. Catálogo no-PII centralizado en `lib/core/services/analytics/`.
   - **Agregar**: taps de botones clave (qué botones se presionan más), screen-flow / `screen_view` consistente vía `SentryNavigatorObserver`+GA4, eventos faltantes para detectar dónde abandonan (drop-off por step), features más usadas. Respetar política no-PII y cardinalidad baja (catálogo hardcoded en `analytics_events.dart`/`analytics_params.dart`).
   - Funnels se ven en consola GA4/BigQuery (sin costo). PostHog se evaluará en una fase futura, fuera de este plan.

## Principios transversales
- **dev → consola, prod → Sentry.** Nunca enviar a Sentry en dev (ni app ni backend).
- **Nunca loguear PII ni secretos** (tokens, Authorization, password, email/teléfono, SOAT, placas, VIN). Redacción + allowlist.
- App aún sin usuarios reales → refactors agresivos OK; los tests deben pasar.
- Mantener Clean Architecture y rideglory-coding-standards. Reusar abstracciones existentes (`CrashReporter`, `AnalyticsService`).
- Cuidar cuota free de Sentry (5k errores/mes): sampling de traces bajo (0.1–0.2 prod, 0 dev), filtrar errores de negocio esperados.

## Fases sugeridas (a refinar en la planeación)
1. Backend: logging estructurado de requests/responses + pino + traceId (gateway y propagación TCP a MS).
2. Backend: Sentry (instrument.ts + module + filtros) gated por NODE_ENV, env joi, tracing distribuido.
3. Flutter: Sentry reemplaza Crashlytics (init, CrashReporter→Sentry, addSentry en Dio, tracePropagationTargets, gating dev/prod), conectado al trace del backend.
4. Insights: expandir Firebase Analytics (taps de botones, screen-flow, eventos de drop-off faltantes), docs de eventos.
