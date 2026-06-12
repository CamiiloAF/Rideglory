# Backend Handoff — backend-errores-5xx-sentry

**Generado:** 2026-06-11T22:51:26Z
**Agente:** backend
**Modelo:** claude-sonnet-4-6
**Iteración:** corrección post-Auditor

---

## Baseline

Tests previos al inicio de la corrección:
- `rideglory-common-lib`: 56 tests, 7 suites — **VERDE**
- `api-gateway`: 110 tests, 11 suites — **VERDE**

---

## Correcciones aplicadas (MODO CORRECCIÓN — Auditor Opus)

### 1. Nombre real de servicio en todos los MS (`main.ts`)

**Problema:** todos los MS llamaban `new RpcAllExceptionsFilter()` sin argumento, produciendo tag `service:'unknown-ms'` en los eventos Sentry en lugar del nombre real.

**Archivos modificados:**
- `users-ms/src/main.ts` → `new RpcAllExceptionsFilter('users-ms')`
- `events-ms/src/main.ts` → `new RpcAllExceptionsFilter('events-ms')`
- `vehicles-ms/src/main.ts` → `new RpcAllExceptionsFilter('vehicles-ms')`
- `maintenances-ms/src/main.ts` → `new RpcAllExceptionsFilter('maintenances-ms')`
- `notifications-ms/src/main.ts` → `new RpcAllExceptionsFilter('notifications-ms')`

### 2. Revertir cambios `city` de `@rideglory/contracts` (AC #10)

**Problema:** la corrida anterior eliminó el campo `city` de tres DTOs de contracts, haciendo el diff de `@rideglory/contracts` no vacío (viola el change map y AC #10).

**Archivos restaurados:**
- `rideglory-contracts/src/events/dto/create-event.dto.ts` → restaurado `city!: string`
- `rideglory-contracts/src/events/dto/event-filter.dto.ts` → restaurado `city?: string`
- `rideglory-contracts/src/ai/dto/ai-description-event-context.dto.ts` → restaurado `city!: string`

**Archivos de api-gateway restaurados a usar `city`:**
- `api-gateway/src/ai/gemini.service.ts` → restaurado `Ciudad: ${eventContext.city}` en contextPrefix y system prompt
- `api-gateway/src/ai/gemini.service.spec.ts` → restaurado `city: 'Bogotá'` en fixture
- `api-gateway/src/ai/ai-description.spec.ts` → restaurado `city: 'Bogotá'` en 3 fixtures
- `api-gateway/src/ai/ai.controller.spec.ts` → restaurado `city: 'Medellín'` en fixture validDto

### 3. `beforeSendLog`: scrub de PII por VALOR en atributos string (AC #12)

**Problema:** `beforeSendLog` solo redactaba atributos cuya clave era PII (e.g. `email: {...}`), pero no scrubaba PII incrustada en el texto del valor de atributos no-PII (e.g. `message: { value: '...email=user@x.com...' }`).

**Archivo modificado:** `rideglory-common-lib/src/sentry/pii-filter.ts`
- El bucle ahora: si la clave es PII → redacta completo; si el valor es un objeto con propiedad `value` de tipo string → aplica `scrubString` sobre ese string; otros → pasa igual.

### 4. Nuevos tests

**`rideglory-common-lib/src/sentry/pii-filter.spec.ts`** — 2 tests adicionales AC #12:
- Verifica que PII incrustada en el valor string del atributo `message` de un log 4xx se redacta.
- Verifica patrón `password=secret` en texto de atributo se redacta.

**`rideglory-common-lib/src/filters/rpc-all-exceptions.filter.spec.ts`** — 10 tests adicionales:
- `it.each` sobre los 5 nombres reales de MS para 5xx y 4xx — verifica que el tag `service` coincide exactamente con el nombre del MS pasado al constructor.

---

## Archivos cambiados (acumulado total desde inicio de fase)

### rideglory-common-lib

| Archivo | Tipo |
|---------|------|
| `src/sentry/init-sentry.ts` | NUEVO |
| `src/sentry/pii-filter.ts` | NUEVO + CORREGIDO (beforeSendLog value scrub) |
| `src/sentry/sentry.module.ts` | NUEVO |
| `src/sentry/index.ts` | NUEVO |
| `src/sentry/pii-filter.spec.ts` | NUEVO + AMPLIADO (AC #12) |
| `src/filters/rpc-all-exceptions.filter.ts` | MODIFICADO |
| `src/filters/rpc-all-exceptions.filter.spec.ts` | NUEVO + AMPLIADO (service-name it.each) |
| `src/index.ts` | MODIFICADO — agrega `export * from './sentry'` |
| `package.json` | MODIFICADO — `@sentry/node` peerDep + devDep |

### api-gateway

| Archivo | Tipo |
|---------|------|
| `src/instrument.ts` | NUEVO |
| `src/instrument.spec.ts` | NUEVO |
| `src/main.ts` | MODIFICADO — `import './instrument'` primera línea |
| `src/config/envs.ts` | MODIFICADO — SENTRY_* vars |
| `src/common/exceptions/rpc-custom-exception.filter.ts` | MODIFICADO |
| `src/common/exceptions/rpc-custom-exception.filter.spec.ts` | NUEVO |
| `src/ai/gemini.service.ts` | RESTAURADO — ciudad de vuelta |
| `src/ai/gemini.service.spec.ts` | RESTAURADO — city fixture |
| `src/ai/ai-description.spec.ts` | RESTAURADO — city fixtures (3) |
| `src/ai/ai.controller.spec.ts` | RESTAURADO — city fixture |
| `package.json` | MODIFICADO — `@sentry/nestjs`, `@sentry/node` |

### Microservicios (users-ms, events-ms, vehicles-ms, maintenances-ms, notifications-ms)

Cada uno:
| Archivo | Tipo |
|---------|------|
| `src/instrument.ts` | NUEVO |
| `src/main.ts` | MODIFICADO — primer import + nombre real en RpcAllExceptionsFilter |
| `src/config/envs.ts` | MODIFICADO — SENTRY_* vars |
| `package.json` | MODIFICADO — `@sentry/node` |

### rideglory-contracts

| Archivo | Tipo |
|---------|------|
| `src/events/dto/create-event.dto.ts` | RESTAURADO — `city` de vuelta |
| `src/events/dto/event-filter.dto.ts` | RESTAURADO — `city` de vuelta |
| `src/ai/dto/ai-description-event-context.dto.ts` | RESTAURADO — `city` de vuelta |

**Diff final de rideglory-contracts: vacío (AC #10 cumplido).**

---

## Pruebas nuevas (acumulado)

### rideglory-common-lib — 68 tests (56 anteriores + 12 nuevos)

**`src/sentry/pii-filter.spec.ts`** — 13 tests total
- `beforeSend`: redacta headers, body objeto/string, extra, exception values; cubre todos PII_SENSITIVE_FIELDS
- `beforeSendLog`: redacta por clave; scruba PII incrustada por valor en `message` (AC #12); patrón `password=key=value`
- `beforeBreadcrumb`: redacta datos PII

**`src/filters/rpc-all-exceptions.filter.spec.ts`** — 16 tests total
- RpcException ≥500 / 400 / 404: captureException / logger.warn / super.catch
- HttpException ≥500 / 400: ídem
- Error genérico: captureException; wrapping RpcException
- `'unknown-ms'` por defecto
- `it.each` 5 nombres reales de MS: tag `service` correcto para 5xx y 4xx

### api-gateway — 110 tests

**`src/instrument.spec.ts`** — 4 tests
**`src/common/exceptions/rpc-custom-exception.filter.spec.ts`** — 11 tests
- tag `service:'api-gateway'`; extra.traceId; shape HTTP intacto; header x-trace-id

---

## Resultado final

| Suite | Tests | Estado |
|-------|-------|--------|
| rideglory-common-lib | 68 | VERDE |
| api-gateway | 110 | VERDE |

**Total: 178 tests — 0 fallidos**

---

## Verificación manual (smoke test)

```bash
# Sin SENTRY_DSN → servicios arrancan normalmente (gate activo)
cd rideglory-api/api-gateway && npm run start:dev
# Esperado: "ApiGateway is running on port..." — sin errores Sentry

# Con SENTRY_DEV_VERIFY=true y DSN → Sentry.init se llama
SENTRY_DEV_VERIFY=true SENTRY_DSN=<dsn> npm run start:dev
# Generar un 500, verificar en dashboard Sentry: tag service=api-gateway + traceId
```

---

## Notas Frontend/QA

- **Sin cambios Flutter**: fase 100% backend.
- **Contrato HTTP intacto**: `RpcCustomExceptionFilter` mantiene `{statusCode, message, traceId?}`.
- **rideglory-contracts diff: vacío** — no hay breaking changes en contratos (AC #10).
- **city restaurado**: `CreateEventDto`, `EventFilterDto`, `AiDescriptionEventContext` mantienen el campo `city` sin cambios respecto al commit base.
- **Variable `SENTRY_DSN` opcional**: en dev sin configurarla, comportamiento idéntico al baseline.
- **Limitación WS**: `/tracking/ws` no participa del tracing Sentry (fuera de alcance — PRD §3).
