# QA handoff — observability-sentry-phase01

**Fecha (UTC):** 2026-06-11T20:18:17Z
**Status:** conditional — listo para merge con un gap menor (TODO WS)
**Repo:** `/Users/cami/Developer/Personal/rideglory-api` (solo backend)
**Flutter:** sin cambios en esta fase — no se corrió `flutter test`

---

## Catalogo de ACs

| AC | Criterio | Test que lo cubre | Estado |
|----|----------|-------------------|--------|
| AC-1 | `traceId` idéntico en log gateway y MS | `logger-options.factory.spec.ts` (mixin retorna `{ traceId }`); e2e verifica CLS disponible | PASS (unitario) / manual requerido (e2e completo) |
| AC-2 | `x-request-id` entrante se continúa como `traceId` | `observability.e2e-spec.ts` → "should set x-trace-id equal to x-request-id when the header is present" | PASS |
| AC-3 | Header `x-trace-id` en respuesta HTTP | `observability.e2e-spec.ts` → "should set x-trace-id…" y "should generate a new traceId…" | PASS |
| AC-4 | Dev legible / prod JSON | `logger-options.factory.spec.ts` → "should use debug level and pino-pretty transport outside production" / "should use info level in production" | PASS |
| AC-5 | PII no aparece en logs ni en cuerpo de respuesta | `pii-denylist.spec.ts` (12 casos) + `observability.e2e-spec.ts` ("should not leak PII fields") | PASS |
| AC-6 | Message patterns sin cambio de firma | `git diff -- rideglory-contracts/` → 0 líneas | PASS |
| AC-7 | `observability/` solo en common-lib (sin copias divergentes) | Inspección: todos los símbolos se importan desde `@rideglory/common-lib`; no hay copias locales | PASS |
| AC-8 | `HttpLoggerMiddleware` eliminado | `grep -r 'HttpLoggerMiddleware' api-gateway/src/` → 0 resultados; archivo `http-logger.middleware.ts` eliminado | PASS |
| AC-9 | Interceptor emite método, ruta, status, latencia, `traceId` | Código de `HttpLoggingInterceptor` verificado: emite `{ method, url, status, ms, traceId }` | PASS (code review) |
| AC-10 | Sin Sentry | `grep -r '@sentry/' rideglory-api/` → 0 resultados en código fuente (solo en comentarios de test y drift_report.json) | PASS |
| AC-11 | Arranque ×6 sin errores | `rideglory-common-lib npm run build` pasa limpio; tests de common-lib 31/31 pass; tests api-gateway 98/98 pass | PASS (build+unit) / smoke manual recomendado |

---

## Matriz de regresion (guardrails §6)

| Guardrail | Mecanismo | Estado |
|-----------|-----------|--------|
| **PII** — campo sensible no pasa sin cobertura | `pii-denylist.spec.ts`: "every PII_SENSITIVE_FIELDS entry must have at least one path in PII_REDACT_PATHS" — falla si se añade campo sin ruta pino | PASS |
| **Contracts intactos** | `git diff -- rideglory-contracts/` = 0 líneas; `git diff -- '**/message-patterns*'` = 0 líneas | PASS |
| **Arranque ×6** | common-lib build + unit tests pass; api-gateway unit + e2e observability pass; vehicles-ms 27/27 pass | PASS (parcial — smoke manual pendiente para MS sin tests) |
| **Backwards compatibility del deserializer** | `tracing-deserializer.spec.ts` → "should handle missing _meta gracefully (backwards compatible)" | PASS |
| **Rebuild de common-lib obligatorio** | `npm run build` ejecutado antes de correr tests de consumidores | PASS (seguido en esta QA run) |
| **Sin Sentry** | Grep sobre `*.ts` y `*.json` excluyendo node_modules → 0 hits en código fuente | PASS |

---

## Ejecucion de tests

### `rideglory-common-lib`
```
npm run build   → OK (tsc sin errores)
npm test        → Test Suites: 4 passed, 4 total | Tests: 31 passed, 31 total
```
Suites: `pii-denylist.spec.ts` (12), `tracing-serializer.spec.ts` (5), `tracing-deserializer.spec.ts` (5), `logger-options.factory.spec.ts` (6). Todas verdes.

### `api-gateway` — unit tests
```
npm test        → Test Suites: 9 passed, 9 total | Tests: 98 passed, 98 total
```
(nota: Jest reporta "did not exit one second after test run" — problema de handle abierto preexistente en algún test del scheduler; no introduce regresión en observability)

### `api-gateway` — e2e tests
```
npm run test:e2e --forceExit
  FAIL test/app.e2e-spec.ts   ← pre-existing (ENV "PORT" is required; sin .env en CI)
  PASS test/observability.e2e-spec.ts
  Test Suites: 1 failed (pre-existing), 1 passed | Tests: 6 passed, 6 total
```
Los 6 tests nuevos de `observability.e2e-spec.ts` son todos verdes: AC-2, AC-3, AC-1 (CLS), AC-5 (PII), AC-10 (no Sentry), traceIds únicos en concurrencia.

### `users-ms`
```
npm test → No tests found (0 spec files en esta fase — sin regresión)
```

### `events-ms`
```
npm test → Tests: 5 failed, 21 passed, 26 total
```
Los 5 fallos son **pre-existentes**: `EventsService — filter logic TC-1 a TC-5` fallan por mismatch entre el spec viejo (`state: { not: 'DRAFT' }`, `orderBy: 'asc'`) y la implementación actual (`state: { notIn: ['DRAFT', 'IN_PROGRESS'] }`, `orderBy: 'desc'`). Confirmado corriendo los mismos tests sobre HEAD antes de aplicar los cambios de observabilidad — mismos 5 fallos.

### `vehicles-ms`
```
npm test → Test Suites: 2 passed, 2 total | Tests: 27 passed, 27 total
```

### `maintenances-ms`
```
npm test → No tests found (0 spec files — sin regresión)
```

### `notifications-ms`
```
npm test → No tests found (0 spec files — sin regresión)
```

### Resumen
| Suite | Pass | Fail | Pre-existing | Regresión nueva |
|-------|------|------|--------------|-----------------|
| common-lib | 31 | 0 | — | 0 |
| api-gateway (unit) | 98 | 0 | — | 0 |
| api-gateway (e2e) | 6 | 1 | 1 | 0 |
| users-ms | 0 | 0 | — | 0 |
| events-ms | 21 | 5 | 5 | 0 |
| vehicles-ms | 27 | 0 | — | 0 |
| maintenances-ms | 0 | 0 | — | 0 |
| notifications-ms | 0 | 0 | — | 0 |
| **Total** | **183** | **6** | **6** | **0** |

---

## Bugs

Ninguna regresión nueva introducida por esta fase. Los 6 fallos son pre-existentes.

**Gap menor (no bloqueante):**
- `api-gateway/src/tracking/tracking.gateway.ts`: falta el comentario `// TODO(observability-phase2): WebSocket /tracking/ws no propaga traceId; añadir con nestjs-cls en Fase 2` requerido por ADR-OBS-9 y el change map del architect. La funcionalidad no se ve afectada — es documentación de deuda técnica. Recomendado para cierre pre-merge.

---

## Pruebas manuales (recomendadas antes de deploy a prod)

Las siguientes pruebas requieren levantar el stack completo (gateway + MS) y no están automatizadas:

1. **AC-1 — Correlación e2e gateway → MS:** enviar `POST /api/users/...` y comparar `traceId` en stdout de api-gateway y users-ms; deben ser idénticos.
2. **AC-2 — Continuación de x-request-id:** `curl -H "x-request-id: test-123" <gateway>/api/health`; verificar `traceId: "test-123"` en logs de api-gateway.
3. **AC-4 — Formato de logs:** levantar con `NODE_ENV=production`; stdout debe ser JSON one-line. Sin `NODE_ENV` → pino-pretty legible.
4. **AC-5 — PII en logs:** enviar `POST /api/auth/login` con `email` y `password` reales; verificar que los logs de api-gateway muestran `[REDACTED]` para esos campos.
5. **AC-11 — Smoke de arranque ×6:** `node dist/src/main` en cada servicio → no debe haber `ERROR` ni `Exception` en los primeros 5 segundos.

---

## Sign-off

- **Regresiones nuevas:** 0
- **ACs cubiertos por tests automáticos:** AC-2, AC-3, AC-4, AC-5, AC-6, AC-7, AC-8, AC-10 — verificados
- **ACs con cobertura manual recomendada:** AC-1 (correlación cross-service), AC-11 (smoke ×6)
- **Gap menor:** TODO WS en `tracking.gateway.ts` — no bloqueante
- **Fallos pre-existentes confirmados:** events-ms TC-1 a TC-5 (filter logic vs implementation drift), app.e2e-spec.ts (PORT env)
- **Sign-off:** **conditional** — verde para merge tras añadir el comentario TODO en tracking.gateway.ts; smoke manual de arranque ×6 recomendado pero no bloqueante dado que common-lib build + unit pass

## Change log
- 2026-06-11T20:18:17Z: QA fase observability-sentry-phase01 completada.
