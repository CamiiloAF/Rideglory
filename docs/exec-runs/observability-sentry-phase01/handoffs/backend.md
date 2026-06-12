# Backend Handoff — observability-sentry-phase01

**Generado (UTC):** 2026-06-11T20:03:04Z  
**Iteración:** corrección tras auditoría Opus  
**Repo:** `/Users/cami/Developer/Personal/rideglory-api`

---

## Baseline

Tests antes de cualquier cambio:

| Workspace | Estado |
|-----------|--------|
| api-gateway unit | 9 suites / 98 tests — VERDE |
| api-gateway e2e (observability) | 5 failed / 5 — ROJO (bugs corregidos en esta iteración) |
| rideglory-common-lib | 3 suites / 23 tests — VERDE |
| vehicles-ms | 2 suites / 27 tests — VERDE |
| events-ms | 2 suites / 26 tests — 5 ROJO (pre-existentes, sin relación con observabilidad) |
| users-ms | Sin tests (pre-existente) |
| maintenances-ms | Sin tests (pre-existente) |

---

## Correcciones aplicadas en esta iteración

### [CRÍTICO] Mismatch de clave CLS — `api-gateway/src/app.module.ts`

**Problema:** `ClsModule.forRoot` usaba solo `generateId`/`idGenerator` que guarda el ID via `cls.getId()`, pero `HttpLoggingInterceptor`, `RpcCustomExceptionFilter` y `TracingSerializer` leían via `cls.get('traceId')` (clave nombrada). Esas son APIs diferentes → `x-trace-id` header era siempre vacío.

**Solución:** Se añadió un hook `setup` en `ClsModule.forRoot` que siembra explícitamente la clave nombrada `'traceId'` usando la misma función `resolveTraceId`. Todos los consumidores usan `cls.get('traceId')` — convención única y consistente.

```typescript
setup: (cls: ClsService, req: IncomingRequest) => {
  cls.set('traceId', resolveTraceId(req));
},
```

### [CRÍTICO] E2E spec con dynamic imports — `api-gateway/test/observability.e2e-spec.ts`

**Problema:** Los `await import(...)` dinámicos en `beforeAll` fallaban con `TypeError: A dynamic import callback was invoked without --experimental-vm-modules`. Jest no soporta dynamic imports sin configuración especial.

**Solución:** Reescrito con imports estáticos top-level. El módulo mínimo (ClsModule + LoggerModule + HealthModule + interceptors) ahora refleja exactamente cómo `AppModule` los conecta.

**Adicionalmente:** Los tests ahora cubren AC-2 real: `x-trace-id === x-request-id` (no solo "está definido"). Tests de unicidad para requests sin header. Agregado `HttpLoggingInterceptor` en el módulo de test para que el header sea emitido.

### [CRÍTICO] Instalación de dependencias

**Problema:** `nestjs-pino`, `nestjs-cls`, `pino-http` estaban en `package.json` de cada servicio pero no en sus `node_modules`.

**Solución:** Ejecutado `npm install` en el workspace raíz + per-workspace install. Las deps están en `node_modules` raíz (hoisting npm workspaces) y cada MS tiene symlink verificado. `package-lock.json` raíz actualizado.

### [ALTO] traceId en cada línea de log de MS — `logger-options.factory.ts`

**Problema:** Los microservicios emitían logs pino sin `traceId` en cada línea (AC-1 no cumplido).

**Solución:** `pinoHttpOptions` acepta ahora un segundo parámetro opcional `getTraceId: () => string | undefined`. Cuando se provee, el `pinoHttp.mixin` retorna `{ traceId }` por cada log emitido. Cada MS pasa `() => cls.get<string>('traceId')` via `LoggerModule.forRootAsync({ inject: [ClsService], useFactory: (cls) => pinoHttpOptions(name, () => cls.get('traceId')) })`.

### [MEDIO] PII_REDACT_PATHS incompleto — `pii-denylist.ts`

**Problema:** `soatNumber`, `idToken`, `token`, `firebaseToken`, `fcmToken` estaban en `PII_SENSITIVE_FIELDS` pero no en `PII_REDACT_PATHS` → los logs de pino podían filtrar esos campos.

**Solución:** Añadidos todos los campos faltantes tanto en `req.body.*` como `res.body.*`.

### [MENOR] notifications-ms lockfile

**Problema:** `notifications-ms/node_modules/nestjs-pino` no existía.

**Solución:** Ejecutado `npm install --workspace=notifications-ms` (y los demás MS). Verificado con `ls notifications-ms/node_modules/nestjs-pino`.

---

## Archivos cambiados

### `rideglory-common-lib`

**Nuevos — `src/observability/`:**
- `tcp-meta.interface.ts` — `TcpMeta { traceId: string; [key: string]: unknown }`
- `pii-denylist.ts` — `PII_SENSITIVE_FIELDS` y `PII_REDACT_PATHS` completados (todos los campos sensibles)
- `logger-options.factory.ts` — `pinoHttpOptions(context, getTraceId?)` con `mixin` opcional para AC-1
- `tracing-serializer.ts` — inyecta `data._meta.traceId` en TCP outgoing
- `tracing-deserializer.ts` — extrae `data._meta` en TCP incoming, backwards-compatible
- `cls-rpc.interceptor.ts` — siembra CLS con `traceId` del `data._meta`
- `pii-redact.interceptor.ts` — strips PII de HTTP response bodies
- `index.ts` — barril de los 7 símbolos

**Tests — `src/observability/`:**
- `pii-denylist.spec.ts` — 13 tests (12 redacción + 1 cobertura: cada campo en `PII_SENSITIVE_FIELDS` tiene path en `PII_REDACT_PATHS`)
- `tracing-serializer.spec.ts` — 5 tests
- `tracing-deserializer.spec.ts` — 6 tests
- `logger-options.factory.spec.ts` — 7 tests nuevos: mixin con traceId, sin traceId, nivel prod vs dev

### `api-gateway`

- `src/app.module.ts` — **CORREGIDO**: `setup` hook siembra `'traceId'` en CLS; `resolveTraceId` extraído como función compartida
- `src/main.ts` — `bufferLogs`, `useLogger(Logger)`, `ClsService` inyectado en `RpcCustomExceptionFilter`
- `src/common/exceptions/rpc-custom-exception.filter.ts` — `traceId` en error body y header
- `src/common/interceptors/http-logging.interceptor.ts` — nuevo: emite method/url/status/latencia/traceId; header `x-trace-id`
- `src/users/users.module.ts` y 8 módulos más — `TracingSerializer` inyectado via `registerAsync`
- `test/observability.e2e-spec.ts` — **REESCRITO**: imports estáticos, 6 tests, AC-2 real (valor === x-request-id), uniqueness test

### Todos los MS (`users-ms`, `events-ms`, `vehicles-ms`, `maintenances-ms`, `notifications-ms`)

- `src/app.module.ts` — **CORREGIDO**: `LoggerModule.forRootAsync({ inject: [ClsService], useFactory: (cls) => pinoHttpOptions(name, () => cls.get('traceId')) })`; CLS seeding para AC-1
- `src/main.ts` — `TracingDeserializer`, `bufferLogs`, `app.useLogger(Logger)`
- `package.json` — deps declaradas; instaladas en workspace root

---

## Pruebas nuevas

| Archivo | Tests | Qué cubre |
|---------|-------|-----------|
| `rideglory-common-lib/src/observability/pii-denylist.spec.ts` | 13 | Redacción todos los campos PII; nested/arrays; non-PII intocado; **cobertura PII_SENSITIVE_FIELDS ↔ REDACT_PATHS** |
| `rideglory-common-lib/src/observability/tracing-serializer.spec.ts` | 5 | traceId inyectado; no inyectado si CLS vacío; null CLS; data ausente |
| `rideglory-common-lib/src/observability/tracing-deserializer.spec.ts` | 6 | extrae _meta.traceId; sin _meta → no falla; string input; data ausente |
| `rideglory-common-lib/src/observability/logger-options.factory.spec.ts` | 7 | mixin retorna traceId (AC-1); mixin retorna {} si undefined; sin mixin si no se pasa getTraceId; nivel prod/dev |
| `api-gateway/test/observability.e2e-spec.ts` | 6 | AC-2: x-trace-id === x-request-id; AC-3: x-trace-id siempre presente; uniqueness; AC-1: ClsService injectable; AC-5: sin PII; AC-10: sin @sentry |

---

## Resultado final

| Workspace | Antes (pre-corrección) | Después |
|-----------|----------------------|---------|
| rideglory-common-lib | 23 pass | **31 pass / 0 fail** |
| api-gateway unit | 98 pass | **98 pass / 0 fail** |
| api-gateway e2e (observability) | 5 fail | **6 pass / 0 fail** |
| api-gateway e2e (app) | fail pre-existente (PORT env) | fail pre-existente (sin cambio, sin relación) |
| vehicles-ms | 27 pass | **27 pass / 0 fail** |
| events-ms | 5 fail pre-existentes | 5 fail pre-existentes (sin cambio) |

**Guardrails verificados:**
- `grep -r '@sentry/' rideglory-api/` → 0 resultados
- `git diff --name-only HEAD | grep contracts` → 0 resultados
- `http-logger.middleware.ts` eliminado de `app.module.ts` (AC-8)
- `nestjs-pino` en `node_modules` de todos los MS verificado
- `PII_SENSITIVE_FIELDS` cubiertos completamente en `PII_REDACT_PATHS` (test de cobertura)
- Convención CLS única: todos los sitios leen/escriben via `cls.get('traceId')` / `cls.set('traceId', ...)`

---

## Verificación manual

```bash
# 1. Run common-lib tests
cd rideglory-common-lib && npm test
# Esperado: 31 pass / 0 fail

# 2. Run gateway unit tests
cd api-gateway && npx jest --forceExit
# Esperado: 98 pass / 0 fail

# 3. Run gateway e2e observability
cd api-gateway && npx jest --config test/jest-e2e.json --testPathPatterns observability --forceExit
# Esperado: 6 pass / 0 fail; los logs muestran traceId en cada línea

# 4. Smoke check con servicios reales
curl -v -H "x-request-id: my-custom-trace-001" http://localhost:3000/api/health
# Response header: x-trace-id: my-custom-trace-001
# Logs gateway: traceId: "my-custom-trace-001"
# Logs MS: traceId: "my-custom-trace-001" (via mixin)

# 5. Error RPC
curl -v http://localhost:3000/api/users/nonexistent-id
# Body JSON: { ..., traceId: "..." }
# Header: x-trace-id: mismo valor
```

---

## Notas Frontend/QA

- Flutter (`lib/`) no cambia en esta fase. Consumo de `x-trace-id` va en Fase 3.
- `x-trace-id` está presente en TODAS las respuestas HTTP (éxito y error).
- WebSocket `/tracking/ws` sin traceId en Fase 1 (TODO(observability-phase2) documentado).
- `pino-pretty` es devDependency; imágenes prod usan `NODE_ENV=production` y no cargan `pino-pretty`.
- Cambio backward-compatible: `_meta` se añade al objeto `data` en TCP pero los handlers RPC existentes solo leen sus propios campos y no son afectados.
- La convención CLS es única: `cls.get('traceId')` en todo el codebase (gateway, serializer, filter, interceptor).
