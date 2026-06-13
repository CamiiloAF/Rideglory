# QA Handoff — backend-errores-5xx-sentry

**Date:** 2026-06-11T23:07:33Z
**Agent:** QA (Sonnet 4.6)
**Slug:** backend-errores-5xx-sentry

---

## Catálogo AC → Tests

| AC | Descripción | Test | Estado |
|----|-------------|------|--------|
| AC-1 | 5xx en gateway → evento Sentry con `tag service: api-gateway` y `traceId` | `rpc-custom-exception.filter.spec.ts`: `calls captureException with service tag for RpcException status 500` + `always tags service as api-gateway for 5xx` (con `extra: { traceId }`) | existente |
| AC-2 | 5xx en MS → evento Sentry con tag `service` correcto y `traceId` propagado | `rpc-all-exceptions.filter.spec.ts`: suite `AC-2: traceId included in captureException extra for 5xx (MS)` (4 tests nuevos) + implementación `ClsLike` en `RpcAllExceptionsFilter` | nuevo (implementado + test) |
| AC-3 | mismo `traceId` en gateway y MS | `rpc-all-exceptions.filter.spec.ts`: suite `AC-3: traceId symmetry` — verifica que el mismo valor de traceId se pasa a `captureException.extra.traceId` en el MS (unit); la integración real requiere prueba manual | nuevo (parcial — unit; integración manual) |
| AC-4 | Error 4xx NO genera error event; SÍ genera `Sentry.logger.warn` con traceId/service/status | `rpc-all-exceptions.filter.spec.ts`: suite `AC-4: traceId included in Sentry.logger.warn for 4xx in MS filter` (3 tests nuevos); implementación incluye `traceId` en ambas ramas `4xx rpc error` y `4xx http error` | nuevo (implementado + test) |
| AC-5 | Sin `NODE_ENV=production` ni `SENTRY_DEV_VERIFY` → ningún evento enviado | `api-gateway/src/instrument.spec.ts`: 4 tests cubriendo gate `NODE_ENV`/`SENTRY_DEV_VERIFY`/dsn-undefined/dsn-provided | existente |
| AC-6 | `import './instrument'` es primera línea de los 6 `main.ts` | Code review: grep confirmó `import './instrument'` en línea 1 de los 6 `main.ts` | code review (ver BUG-2) |
| AC-7 | Los 6 `config/envs.ts` aceptan `SENTRY_DSN` vacío sin error | joi `string().uri().optional()` en los 6 envs.ts verificado por grep | code review (ver BUG-2) |
| AC-8 | Ningún evento Sentry contiene PII de la denylist | `pii-filter.spec.ts`: 8 tests cubriendo `beforeSend`/`beforeSendLog`/`beforeBreadcrumb` + suite `covers all PII_SENSITIVE_FIELDS` | existente |
| AC-9 | Abstracción en common-lib; 6 servicios compilan | `npm test` en common-lib con 76 tests pasa limpio | existente |
| AC-10 | Diff vacío en `@rideglory/contracts` | `git diff HEAD -- rideglory-contracts/` → salida vacía | verificado |
| AC-11 | `captureException` para >=500, NO para 400/404; `Sentry.logger.warn` para 400/404 | `rpc-all-exceptions.filter.spec.ts` + `rpc-custom-exception.filter.spec.ts`: múltiples tests para ambas ramas | existente |
| AC-12 | Structured logs 4xx no contienen PII | `pii-filter.spec.ts`: `scrubs PII embedded by VALUE in string attributes (AC #12)` | existente |

---

## Matriz de Regresión

| Guardrail | Mecanismo de verificación | Estado |
|-----------|--------------------------|--------|
| Contrato HTTP hacia Flutter (`{ statusCode, message }` + `x-trace-id`) | `rpc-custom-exception.filter.spec.ts`: `preserves HTTP response shape { statusCode, message } for 500/400` + `includes traceId in response header and body` | cubierto |
| Sin cambios en `@rideglory/contracts` (DTOs, message patterns) | `git diff HEAD -- rideglory-contracts/` vacío | cubierto |
| Filtros de excepción mantienen flujo de re-lanzado | `still calls super.catch to preserve re-throw flow` en ambas suites de filtros | cubierto |
| Dev local no se rompe sin DSN | joi `optional()` en los 6 envs.ts; gate en `initSentry` retorna si DSN ausente | parcial (ver BUG-2) |
| `beforeSend` PII como gate de seguridad | `pii-filter.spec.ts` completo + suite `covers all PII_SENSITIVE_FIELDS` | cubierto |
| Rebuild de common-lib disciplinado | `npm test` en common-lib con 76 tests pasa limpio | cubierto |
| Palanca `SENTRY_DEV_VERIFY` reversible | Documentada en architect.md; tests de gate en instrument.spec.ts | cubierto |

---

## Ejecución de Tests

### rideglory-common-lib
```
Test Suites: 7 passed, 7 total
Tests:       76 passed, 76 total  (+8 tests nuevos respecto al baseline de 68)
```

Suites corridas:
- `src/filters/rpc-all-exceptions.filter.spec.ts` — 26 tests (era 17, +9 nuevos)
- `src/sentry/pii-filter.spec.ts` — 8 tests
- `src/observability/*.spec.ts` — 42 tests (pre-existing)

### api-gateway
```
Test Suites: 11 passed, 11 total
Tests:       110 passed, 110 total  (sin cambios)
```

Suites relevantes:
- `src/common/exceptions/rpc-custom-exception.filter.spec.ts` — 8 tests
- `src/instrument.spec.ts` — 4 tests

---

## Bugs

### BUG-1 (RESUELTO via implementacion): `RpcAllExceptionsFilter` no propagaba `traceId` a Sentry

**Area:** backend
**Archivo:** `rideglory-api/rideglory-common-lib/src/filters/rpc-all-exceptions.filter.ts`

El filtro no tenia inyeccion de `ClsService` y llamaba a `captureException` sin `extra: { traceId }` y `Sentry.logger.warn` sin `traceId`. Esto rompia AC-2 y AC-4.

**Fix aplicado:** Se aniadio el tipo `ClsLike` (duck-typed, sin hard dep en `nestjs-cls`) como segundo parametro opcional del constructor. Todas las llamadas a `captureException` ahora incluyen `extra: { traceId }` y las de `Sentry.logger.warn` incluyen `traceId`. El spec fue actualizado de un assert exacto `{ tags: { service } }` a `objectContaining` + assert positivo de `extra.traceId`.

---

### BUG-2 (ABIERTO): `instrument.ts` importa `envs` antes de `dotenv/config` — falla joi en dev local

**Area:** backend
**Archivos afectados (los 6):**
- `rideglory-api/api-gateway/src/instrument.ts`
- `rideglory-api/users-ms/src/instrument.ts`
- `rideglory-api/events-ms/src/instrument.ts`
- `rideglory-api/vehicles-ms/src/instrument.ts`
- `rideglory-api/maintenances-ms/src/instrument.ts`
- `rideglory-api/notifications-ms/src/instrument.ts`

**Descripcion:** Cada `instrument.ts` importa `envs` (que ejecuta `joi.validate(process.env)` al instanciarse como modulo). Esto ocurre ANTES de que `main.ts` cargue `import 'dotenv/config'`. En desarrollo local donde `PORT`, `DATABASE_URL` y otras variables vienen del `.env`, joi arrojara `ENV config validation error: "PORT" is required` al arrancar con `ts-node` o `tsx`.

En produccion (Docker/cloud), las vars son inyectadas por el runtime antes del proceso Node.js — sin impacto. El riesgo esta en **dev local con `.env` file** (CA-7 falla en ese escenario).

**Fix recomendado:** Leer `process.env.SENTRY_DSN` directamente en `instrument.ts` sin importar `envs`:

```typescript
// instrument.ts
import { initSentry } from '@rideglory/common-lib';

const dsn = process.env['SENTRY_DSN'];
const rate = process.env['SENTRY_TRACES_SAMPLE_RATE'];
initSentry('api-gateway', dsn, {
  tracesSampleRate: rate ? Number(rate) : undefined,
});
```

---

## Pruebas Manuales Recomendadas

1. **Smoke test dev local:** Arrancar los 6 servicios sin `SENTRY_DSN` en `.env` (solo variables requeridas) para confirmar que BUG-2 se manifiesta o no en el entorno del equipo.
2. **Gate de activacion:** Con `SENTRY_DEV_VERIFY=true` y `SENTRY_DSN` de test, provocar un 500 en el gateway y verificar que llega a Sentry con `tag service: api-gateway` y `extra.traceId` en el evento.
3. **4xx no genera issue:** Provocar un 404 y verificar en Sentry que NO aparece como error event, solo como structured log.
4. **Shape de respuesta HTTP:** Curl al gateway con un 500 — respuesta debe ser `{ statusCode: 500, message: "...", traceId: "..." }` con header `x-trace-id`.
5. **PII:** Provocar un error con datos PII en el payload y verificar en Sentry que los campos aparecen como `[Filtered]`.

---

## Sign-off

**Resultado:** conditional

**Condiciones para green:**
1. BUG-2 resuelto o aceptado por el equipo (solo afecta dev local con `.env` files; produccion no impactada).
2. Smoke test manual de arranque de los 6 servicios exitoso (CA-7).
3. Prueba manual de un 500 real llegando a Sentry con `traceId` correcto (AC-1, AC-2, AC-3 integracion).

**Tests aprobados:** 186 total (76 common-lib + 110 api-gateway), 0 fallos.
**Regresiones introducidas:** Ninguna en el comportamiento existente.
**Implementacion aplicada:** `RpcAllExceptionsFilter` ahora inyecta `ClsLike` y propaga `traceId` a Sentry en todas las ramas (5xx captureException + 4xx logger.warn).
