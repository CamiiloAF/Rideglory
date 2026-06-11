# 00 — Intake — Observabilidad unificada (Sentry + logging estructurado + insights)

- **Slug:** `observability-sentry`
- **Fecha (UTC):** 2026-06-10T22:05:33Z
- **Repos afectados:** Flutter (`/Users/cami/Developer/Personal/Rideglory`) + backend NestJS (`/Users/cami/Developer/Personal/rideglory-api`)

## Fuente

`docs/plans/observability-sentry/BRIEF.md` (leído completo). Brief refinado con el usuario;
incluye decisiones tomadas, principios transversales y 4 fases sugeridas.

## Objetivo

Reconstruir de raíz el sistema de logs y manejo de errores de app y backend con observabilidad
unificada: Sentry (reemplaza Crashlytics en Flutter; nuevo en backend), logging estructurado y
legible de requests/responses en el gateway, tracing distribuido móvil→backend→MS, y más insights
de comportamiento de usuario vía Firebase Analytics. Regla de oro: **dev → consola, prod → Sentry**;
nunca PII ni secretos en logs.

## Alcance percibido

**Backend (rideglory-api) — mayor dolor:**
- Logging estructurado con **pino** (`nestjs-pino`): `pino-pretty` en dev, JSON en prod; encapsula el `Logger` de Nest.
- Interceptor/middleware de **requests/responses** en api-gateway: método, ruta, status, latencia, traceId; redacción de tokens/PII + allowlist.
- **traceId/correlationId**: generar en gateway si no llega; propagar al cliente (headers), **en el payload de los message patterns TCP** hacia los MS, y como tag en Sentry.
- **Sentry**: `instrument.ts` por servicio + `SentryModule.forRoot()` + `SentryGlobalFilter`/`@SentryExceptionCaptured()` en filtros existentes (`RpcCustomExceptionFilter`, `RpcAllExceptionsFilter`); `enabled: NODE_ENV==='production'`.
- Añadir **`NODE_ENV` y `SENTRY_DSN`** al joi de cada `config/envs.ts`. Decidir 1 proyecto Sentry por servicio vs. compartido con tag `service`.
- Manejo de errores uniforme con traceId al cliente; loguear 4xx (hoy solo ≥500).
- Tracing distribuido: gateway continúa el trace de Flutter (`sentry-trace`) y lo propaga.

**Flutter:**
- `SentryCrashReporter` reemplaza `FirebaseCrashReporter` reusando la interface `CrashReporter` (`lib/core/services/crash/`).
- Quitar `firebase_crashlytics` + su init/custom keys (`firebase_module.dart:32-39`).
- `SentryFlutter.init` en `main.dart`: DSN vacío en dev, `environment` por flavor, `beforeSend→null` en dev, `debug=isDev`. Evitar doble reporte (revisar `crash_handler_setup.dart` + `runZonedGuarded`).
- `dio.addSentry()` al final del init de `AppDio`; `tracePropagationTargets` solo API Rideglory.
- Mapear clasificación de errores existente (matriz G5, `network_error_classifier.dart`) a `level`/`fingerprint`/filtrado; no reportar 4xx de negocio. Breadcrumbs en auth/submit.

**Insights de producto (Firebase Analytics / GA4):**
- Expandir lo ya instrumentado (embudos de creación de evento, registro, auth, lectura).
- Agregar: taps de botones clave, `screen_view` consistente (`SentryNavigatorObserver`+GA4), eventos de drop-off faltantes por step, features más usadas. No-PII, cardinalidad baja (catálogo hardcoded).
- Docs de eventos. PostHog fuera de alcance.

**Fases sugeridas (a refinar):**
1. Backend: logging estructurado requests/responses + pino + traceId (gateway + propagación TCP).
2. Backend: Sentry (instrument.ts + module + filtros) gated por NODE_ENV, env joi, tracing distribuido.
3. Flutter: Sentry reemplaza Crashlytics + addSentry en Dio + gating dev/prod, conectado al trace backend.
4. Insights: expandir Firebase Analytics + docs.

## Preguntas abiertas

1. **Sentry projects backend:** ¿un proyecto por servicio (filtrado limpio, recomendado en el brief) o uno compartido con tag `service`? Impacta config y cuota.
2. **Cuota free 5k errores/mes:** ¿basta el filtrado de 4xx de negocio + sampling 0.1–0.2 prod, o se necesita rate-limiting/`beforeSend` adicional?
3. **DSN management:** ¿dónde viven los DSN de prod? (`config/prod.json` / `--dart-define` en Flutter; `.env`/secret manager en backend). ¿Cómo se inyectan en CI/build?
4. **Propagación traceId en TCP:** ¿se modifica el shape de TODOS los message patterns (wrapper `{ data, meta: { traceId } }`) o un mecanismo menos invasivo? Coordinar con `@rideglory/contracts`.
5. **`tracePropagationTargets` en Flutter:** ¿basta el dominio prod, o también el host de dev local (`localhost:3000`, `10.0.2.2:3000`) para validar el trace end-to-end en desarrollo?
6. **Migración Crashlytics:** ¿se retira por completo `firebase_crashlytics` del pubspec y de iOS/Android nativo, o se deja la pieza nativa por si acaso? ¿Histórico de Crashlytics a conservar?
7. **Performance/tracing sampling Flutter:** ¿`tracesSampleRate` deseado en prod? ¿Se habilita profiling?
8. **Alcance de redacción PII:** confirmar la allowlist exacta de campos logueables vs. denylist (Authorization, ID token, password, email, teléfono, SOAT, placa, VIN).
