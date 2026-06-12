# SUMMARY — observability-sentry-phase01

**Tech Lead review (UTC):** 2026-06-11T20:35:54Z
**Veredicto:** ready (segunda iteración — correcciones aplicadas)
**Repo backend:** `/Users/cami/Developer/Personal/rideglory-api`
**Flutter:** sin cambios en esta fase (cambios en `lib/` del working tree pertenecen a `event-form-stepper` — no incluir en commit)

---

## Objetivo

Infraestructura fundacional de observabilidad: propagación de `traceId` desde el gateway HTTP hasta cada microservicio TCP via envelope `_meta`, logs estructurados JSON/pino-pretty, redacción PII en doble capa, y header `x-trace-id` en todas las respuestas HTTP. Sin Sentry (Fase 2). Sin cambios en `@rideglory/contracts` ni message patterns.

---

## Qué cambió por área

### `rideglory-common-lib/src/observability/` (nuevo)
7 archivos nuevos + `index.ts` barril + export desde `src/index.ts`:
- `tcp-meta.interface.ts` — define `TcpMeta { traceId: string; [key]: unknown }`
- `tracing-serializer.ts` — inyecta `_meta.traceId` en TCP saliente (gateway)
- `tracing-deserializer.ts` — extrae `_meta.traceId` en TCP entrante (MS); backwards-compatible
- `cls-rpc.interceptor.ts` — MS-side: siembra CLS con `traceId` de `data._meta` (**ver blocker**)
- `pii-denylist.ts` — `PII_SENSITIVE_FIELDS` + `PII_REDACT_PATHS` centralizados (13 campos)
- `pii-redact.interceptor.ts` — strips PII de HTTP response bodies en gateway
- `logger-options.factory.ts` — factory `pinoHttpOptions(context, getTraceId?)` compartida ×6 servicios

5 spec files: `pii-denylist.spec.ts` (13: 12 redacción + 1 cobertura), `tracing-serializer.spec.ts` (5), `tracing-deserializer.spec.ts` (6), `logger-options.factory.spec.ts` (7), `cls-rpc.interceptor.spec.ts` (4) — total 35/35 verde.

### `api-gateway`
- `app.module.ts` — `ClsModule.forRoot` con `middleware.mount: true` + `setup` hook siembra `cls.set('traceId', ...)`; `LoggerModule.forRootAsync`; elimina `HttpLoggerMiddleware`; `PiiRedactInterceptor` + `HttpLoggingInterceptor` como `APP_INTERCEPTOR` globales.
- `main.ts` — `bufferLogs: true`, `app.useLogger(Logger)`, `ClsService` inyectado en `RpcCustomExceptionFilter`.
- `rpc-custom-exception.filter.ts` — añade `traceId` al body de error y header `x-trace-id`.
- `common/interceptors/http-logging.interceptor.ts` — nuevo: emite `{ method, url, status, ms, traceId }` + header `x-trace-id`.
- `common/middleware/http-logger.middleware.ts` — eliminado (AC-8 cumplido).
- 9 módulos gateway — `TracingSerializer` via `ClientsModule.registerAsync` con `ClsService` inyectado.
- `test/observability.e2e-spec.ts` — nuevo: 6 tests, imports estáticos, cubre AC-1(CLS), AC-2, AC-3, AC-5(PII), AC-10(no Sentry), uniqueness.

### Todos los MS (`users-ms`, `events-ms`, `vehicles-ms`, `maintenances-ms`, `notifications-ms`)
- `package.json` — añaden `nestjs-pino`, `pino-http`, `pino-pretty`, `nestjs-cls`.
- `main.ts` — `TracingDeserializer` como `deserializer`, `bufferLogs: true`, `app.useLogger(Logger)`.
- `app.module.ts` — `LoggerModule.forRootAsync` con `getTraceId: () => cls.get('traceId')` (mixin activo); `ClsModule.forRoot({ middleware: { mount: false } })`; `ClsRpcInterceptor` como `APP_INTERCEPTOR` (siembra via `cls.run()` — corrección del bloqueante crítico aplicada).

### `rideglory-contracts`
Sin cambios. Diff limpio (AC-6 cumplido).

---

## Archivos

**Backend (`rideglory-api` submodules):**
- `rideglory-common-lib/src/observability/` — 12 archivos (7 implementación + 4 specs + index) [create]
- `rideglory-common-lib/src/index.ts` [modify]
- `rideglory-common-lib/package.json` [modify]
- `api-gateway/src/app.module.ts` [modify]
- `api-gateway/src/main.ts` [modify]
- `api-gateway/src/common/exceptions/rpc-custom-exception.filter.ts` [modify]
- `api-gateway/src/common/interceptors/http-logging.interceptor.ts` [create]
- `api-gateway/src/common/middleware/http-logger.middleware.ts` [delete]
- `api-gateway/src/{users,events,vehicles,maintenances,home,tracking,registrations,notifications,scheduler}/*.module.ts` (9) [modify]
- `api-gateway/test/observability.e2e-spec.ts` [create]
- `{users,events,vehicles,maintenances,notifications}-ms/src/main.ts` (5) [modify]
- `{users,events,vehicles,maintenances,notifications}-ms/src/app.module.ts` (5) [modify]
- `{users,events,vehicles,maintenances,notifications}-ms/package.json` (5) [modify]

**Flutter (`lib/`) — FUERA DE ESTA FASE:**
Los cambios en `lib/features/events/presentation/form/` y `lib/l10n/` son de feature/event-form-stepper. No incluir en este commit.

---

## Pruebas

| Suite | Pass | Fail | Regresión nueva |
|-------|------|------|-----------------|
| common-lib | 35 | 0 | 0 |
| api-gateway (unit) | 98 | 0 | 0 |
| api-gateway (e2e observability) | 6 | 0 | 0 |
| api-gateway (e2e app) | — | 1 pre-existing | 0 |
| vehicles-ms | 27 | 0 | 0 |
| events-ms | 21 | 5 pre-existing | 0 |
| users-ms / maintenances-ms / notifications-ms | 0 | 0 | 0 |

---

## Riesgos / Watchlist

### Watchlist (no bloqueante)

- `x-request-id` sin validación de longitud → anotar para joi en Fase 2
- `pino-pretty` como devDependency: mitigado por factory que omite transport en prod; verificar en deploy
- Correlación AC-1 sin cobertura e2e completa (stack real): smoke manual recomendado
- TODO WebSocket en `tracking.module.ts` en vez de `tracking.gateway.ts` (ADR-OBS-9): diferencia de ubicación menor, deuda documentada

---

## Mensaje de commit sugerido

```
feat(observability): traceId distribuido gateway→MS, logs pino, redacción PII (fase 1)

- rideglory-common-lib/src/observability/: TcpMeta, TracingSerializer/Deserializer,
  ClsRpcInterceptor (cls.run() context para TCP), PiiDenylist (13 campos),
  PiiRedactInterceptor, pinoHttpOptions(context, getTraceId?) con mixin opcional
- api-gateway: ClsModule middleware + setup hook (traceId en CLS por request),
  LoggerModule pino, HttpLoggingInterceptor (x-trace-id header + AC-9),
  traceId en error body, TracingSerializer en 9 módulos; elimina HttpLoggerMiddleware
- ×5 microservicios: TracingDeserializer, ClsRpcInterceptor global con cls.run(),
  LoggerModule con mixin traceId por línea de log (AC-1)
- Tests: 35/35 common-lib (incl. cls-rpc interceptor spec), 98/98 gateway unit,
  6/6 e2e observability; 0 regresiones nuevas
- Sin @sentry/* (Fase 2), sin cambios en @rideglory/contracts ni message patterns
