# Tech Lead Review — observability-sentry-phase01

**Generado (UTC):** 2026-06-11T20:35:54Z
**Revisión:** post-auditoría Opus (segunda iteración — correcciones aplicadas)
**Repo backend:** `/Users/cami/Developer/Personal/rideglory-api`
**Flutter:** sin cambios en esta fase (los cambios de `lib/` en el working tree pertenecen a `event-form-stepper`, rama diferente — no incluir en commit)

---

## Veredicto

**APROBADO — listo para commit**

El bloqueante crítico identificado por la auditoría Opus (CLS sin contexto activo en MS → `cls.set` lanzaba excepción en cada RPC trazado) fue corregido: `ClsRpcInterceptor.intercept()` ahora abre el contexto con `cls.run()` antes de llamar `cls.set()`. Se añadió el spec unitario `cls-rpc.interceptor.spec.ts` con 4 tests que cubren los casos críticos. Todos los ACs verificables por tests automáticos pasan verde. No hay regresiones nuevas.

---

## Hallazgos

### Correcciones post-auditoría — verificadas como aplicadas

| ID | Hallazgo original | Estado |
|----|----------|--------|
| FIX-1 | `ClsRpcInterceptor` usa `cls.run()` antes de `cls.set` — el bug crítico de la auditoría | Corregido y testeado |
| FIX-2 | `ClsModule.forRoot` en gateway tiene `setup` hook que siembra `cls.set('traceId', ...)` (convención única) | Corregido |
| FIX-3 | `pinoHttpOptions` acepta `getTraceId?` callback → mixin por línea de log en MS (AC-1) | Corregido |
| FIX-4 | `PII_REDACT_PATHS` ampliado con `soatNumber`, `idToken`, `token`, `firebaseToken`, `fcmToken` en `req.body.*` y `res.body.*` | Corregido |
| FIX-5 | `cls-rpc.interceptor.spec.ts` añadido: 4 tests (con traceId, sin `_meta`, sin contexto previo, non-RPC) | Añadido |
| FIX-6 | E2E reescrito con imports estáticos; 6 tests verdes | Corregido |

### Observaciones menores (no bloqueantes)

| ID | Observación | Severidad |
|----|-------------|-----------|
| OBS-1 | El TODO WebSocket está en `tracking.module.ts` línea 14, no en `tracking.gateway.ts` como especificó ADR-OBS-9. La deuda queda documentada; solo es diferencia de ubicación. | Menor |
| OBS-2 | `ClsRpcInterceptor` usa `private readonly cls: any` — necesario para evitar dependencia dura de `nestjs-cls` en `common-lib`. El comentario lo explica. Aceptable. | Info |
| OBS-3 | El test de AC-1 en el e2e solo verifica que `ClsService` es inyectable (no la correlación cross-service). Correlación real requiere stack completo; documentada como manual recomendado en QA. Aceptable para esta fase. | Menor |
| OBS-4 | `x-request-id` se pasa al traceId sin validar longitud. Sin joi en Fase 1 (per PRD §3). Watchlist para Fase 2. | Info |

---

## Seguridad

| Check | Estado |
|-------|--------|
| Secretos hardcodeados | OK — sin secretos en el diff |
| PII en logs | OK — doble capa: `pii-denylist.ts` (`redact` pino) + `PiiRedactInterceptor` (HTTP response) |
| PII cobertura completa | OK — test anti-regresión: cada campo en `PII_SENSITIVE_FIELDS` tiene path en `PII_REDACT_PATHS` |
| Stack trace en respuestas | OK — `RpcCustomExceptionFilter` solo expone `statusCode`, `message`, `traceId`; sin `stack` |
| `PiiRedactInterceptor` scope | OK — solo en gateway; MS son internos |
| `@sentry/*` en scope | OK — grep sobre `*/src/*.ts` = 0 resultados |
| SQL concatenado | N/A — sin cambios en queries |

---

## Arquitectura

| Check | Estado |
|-------|--------|
| `@rideglory/contracts` sin cambios | OK — `grep -r observability rideglory-contracts/src/` = 0 |
| Message patterns ~56: sin cambio de firma | OK — `_meta` va en `data` como propiedad adicional |
| Backwards compatibility del deserializer | OK — `tracing-deserializer.spec.ts`: envelope sin `_meta` no falla |
| Símbolos solo en `common-lib/observability/` (sin copias) | OK — 7 archivos nuevos + barril; todos importan desde `@rideglory/common-lib` |
| `http-logger.middleware.ts` eliminado | OK — archivo deleted; no referenciado en `app.module.ts` |
| Flutter `lib/` sin cambios | OK — cambios del working tree son de `event-form-stepper` |
| 9 módulos gateway con `TracingSerializer` | OK — verificado por grep en todos los módulos con `ClientsModule` |
| 5 MS con `TracingDeserializer` en `main.ts` | OK — verificado en `users-ms`, `events-ms`, `vehicles-ms`, `maintenances-ms`, `notifications-ms` |
| CLS gateway: `setup` hook con `resolveTraceId` | OK — función extraída, sin duplicación entre `idGenerator` y `setup` hook (misma función) |
| CLS en MS: `cls.run()` abre contexto antes de `cls.set()` | OK — corregido por FIX-1 |
| Envelope `TcpMeta` extensible | OK — `{ traceId: string; [key: string]: unknown }` — Fase 2 puede añadir `sentryTrace`/`baggage` |

---

## Tests

| Suite | Resultado | Nuevos en esta fase |
|-------|-----------|---------------------|
| `rideglory-common-lib` (31 tests) | VERDE | 31 nuevos (pii-denylist: 13, serializer: 5, deserializer: 6, logger-factory: 7) |
| `rideglory-common-lib` cls-rpc interceptor (4 tests) | VERDE | 4 nuevos (FIX-5) |
| `api-gateway` unit (98 tests) | VERDE | 0 nuevos |
| `api-gateway` e2e observability (6 tests) | VERDE | 6 nuevos |
| `api-gateway` e2e app | 1 FAIL pre-existing (PORT env) | Sin relación |
| `vehicles-ms` (27 tests) | VERDE | Sin regresión |
| `events-ms` | 5 FAIL pre-existing | Sin relación |
| `users-ms / maintenances-ms / notifications-ms` | 0 specs | Sin regresión |

Cobertura de ACs por tests automáticos: AC-2, AC-3, AC-4, AC-5, AC-6, AC-7, AC-8, AC-10 — verificados. AC-1 (correlación cross-service) y AC-11 (smoke ×6) requieren verificación manual con stack completo.

---

## Pruebas manuales (antes de deploy a prod)

1. **AC-1 correlación:** levantar gateway + users-ms; enviar `GET /api/users/me`; comparar `traceId` en stdout de ambos — deben ser idénticos.
2. **AC-2 continuación:** `curl -H "x-request-id: test-abc-001" http://localhost:3000/api/health` → response header `x-trace-id: test-abc-001`.
3. **AC-4 formato prod:** arrancar con `NODE_ENV=production`; stdout one-line JSON, sin pino-pretty.
4. **AC-5 PII:** `POST /api/auth/login` con email/password reales → logs muestran `[REDACTED]`.
5. **AC-11 smoke ×6:** `node dist/src/main` en cada servicio → 0 `ERROR` ni `Exception` en primeros 5 segundos.
6. **Regresión RPC:** enviar request que cruza gateway → cualquier MS → verificar ausencia de `"No CLS context available"` en logs del MS.

---

## Nota de commit

Solo commitear en `rideglory-api` (submodules dirty + `package-lock.json` raíz). Los archivos Flutter del working tree (`lib/features/events/...`, `lib/l10n/...`) son de `event-form-stepper` — NO incluir.
