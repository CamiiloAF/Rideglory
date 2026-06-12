# Architect handoff — backend-errores-5xx-sentry

**Date:** 2026-06-11T22:22:09Z
**Status:** done
**Slug:** backend-errores-5xx-sentry
**PRD source:** docs/exec-runs/backend-errores-5xx-sentry/PRD_NORMALIZED.md

---

## Decisiones

| # | Decisión | Rationale |
|---|----------|-----------|
| D1 | `initSentry` helper + `SentryModule` viven en `rideglory-common-lib/src/sentry/` | Previene divergencia ×6; es constraint explícito del PRD (§7). |
| D2 | `@sentry/nestjs` en api-gateway; `@sentry/node` en los 5 MS TCP | api-gateway usa HTTP transport (Express-under-the-hood); los MS usan TCP sin HTTP middleware. `@sentry/nestjs` instrumenta NestJS lifecycle requests; en MS TCP no aplica y la integración NestJS fallaría. |
| D3 | `instrument.ts` es un módulo side-effect puro, importado como primera línea de cada `main.ts` antes de `import 'dotenv/config'` | SDK de Sentry requiere cargarse antes que cualquier `require`/`import` de NestJS para parchear correctamente. `dotenv/config` ya es la primera línea; `./instrument` debe ir ANTES de ella. |
| D4 | Gate de activación: `NODE_ENV === 'production' || SENTRY_DEV_VERIFY === 'true'` dentro de `initSentry` | Permite verificación en staging/local sin cambiar `NODE_ENV`; la palanca es reversible (se documenta su eliminación al cerrar fases Sentry). |
| D5 | `SENTRY_DSN` validado como `joi.string().uri().optional()` en los 6 `envs.ts` | Si falta, `initSentry` no llama a `Sentry.init` y el servicio arranca normalmente (CA §5). |
| D6 | `RpcAllExceptionsFilter` en common-lib se extiende in-place: `status >= 500` → `captureException`; 4xx → `Sentry.logger.warn` | La extensión es aditiva; el flujo de control existente (re-throw `RpcException`) no se altera. |
| D7 | `RpcCustomExceptionFilter` en api-gateway se extiende in-place: misma lógica 5xx/4xx con `cls.get('traceId')` y tag `service: 'api-gateway'` | Simetría con D6; ya tiene acceso a `ClsService`. |
| D8 | Tag `service` definido como constante string en cada `instrument.ts` propio | Evita acoplamiento entre MS; el valor se pasa como argumento a `initSentry(service, dsn)`. |
| D9 | `tracesSampleRate` leído de env `SENTRY_TRACES_SAMPLE_RATE` (default `0.1` en prod) | Controla el volumen de traces en la cuota free. Configurable sin redeploy. |
| D10 | `beforeSend` / `beforeSendLog` / `beforeBreadcrumb` centralizados en `rideglory-common-lib/src/sentry/pii-filter.ts`, reutilizando `PII_SENSITIVE_FIELDS` ya existente | Single source of truth para la denylist; el test existente `pii-denylist.spec.ts` se extiende para cubrir `beforeSend`. |
| D11 | `enableLogs: true` en `Sentry.init` para habilitar structured logs de 4xx | Requisito explícito del PRD §3. |
| D12 | `SentryModule` es un `@Global() @Module()` estático en common-lib que no registra providers propios; solo documenta el patrón de importación de `instrument.ts` | No tiene sentido usar un NestJS Module para la inicialización de Sentry (que ocurre antes del bootstrap); `SentryModule` existe solo para cumplir el naming del PRD y como punto de documentación. En la práctica el backend agent puede omitirlo si no agrega valor. Alternativa viable: no crear `SentryModule` y solo exponer `initSentry`. |
| D13 | Rebuild de common-lib obligatorio antes de reinstalar en los 6 servicios | Gotcha documentado en `project_contracts_rebuild_gotcha.md` en memoria del sistema. |

---

## Change map

### rideglory-common-lib

| File | Action | Reason | Risk |
|------|--------|--------|------|
| `rideglory-common-lib/src/sentry/init-sentry.ts` | create | Helper `initSentry(service, dsn, opts?)` con gate `NODE_ENV`/`SENTRY_DEV_VERIFY`; llama `Sentry.init` con `beforeSend`, `beforeSendLog`, `beforeBreadcrumb`, `enableLogs: true`, `tracesSampleRate` | low |
| `rideglory-common-lib/src/sentry/pii-filter.ts` | create | Implementa `beforeSend`, `beforeSendLog`, `beforeBreadcrumb` redactando campos de `PII_SENSITIVE_FIELDS`; importa la lista existente | low |
| `rideglory-common-lib/src/sentry/sentry.module.ts` | create | `@Global() @Module({})` stub — documentación del patrón; exporta `SentryModule` | low |
| `rideglory-common-lib/src/sentry/index.ts` | create | Barrel: `export * from './init-sentry'; export * from './pii-filter'; export * from './sentry.module'` | low |
| `rideglory-common-lib/src/index.ts` | modify | Agregar `export * from './sentry'` | low |
| `rideglory-common-lib/src/filters/rpc-all-exceptions.filter.ts` | modify | Extensión aditiva: importar `* as Sentry` de `@sentry/node`; en rama `status >= 500` → `captureException(exception, { tags: { service } })`; en rama 4xx → `Sentry.logger.warn(...)`. El parámetro `service` llega a través de un constructor opcional o se lee de `process.env.SENTRY_SERVICE_TAG`. | med |
| `rideglory-common-lib/package.json` | modify | Agregar `@sentry/node` como `peerDependency`; instalarlo como `devDependency` para tests | low |

### api-gateway

| File | Action | Reason | Risk |
|------|--------|--------|------|
| `api-gateway/src/instrument.ts` | create | `import './instrument'` side-effect: llama `initSentry('api-gateway', envs.sentryDsn)` usando `@sentry/nestjs` en lugar de `@sentry/node` | low |
| `api-gateway/src/main.ts` | modify | Agregar `import './instrument';` como PRIMERA línea (antes de `import 'dotenv/config'`) | med |
| `api-gateway/src/config/envs.ts` | modify | Agregar `SENTRY_DSN?: string`, `SENTRY_TRACES_SAMPLE_RATE?: number`, `SENTRY_DEV_VERIFY?: string` en interfaz + schema joi + objeto `envs` | low |
| `api-gateway/src/common/exceptions/rpc-custom-exception.filter.ts` | modify | Importar `* as Sentry`; en `catch()`: `status >= 500` → `captureException`; `status < 500` → `Sentry.logger.warn`; ambos con `{ tags: { service: 'api-gateway' }, extra: { traceId } }` | med |
| `api-gateway/package.json` | modify | Agregar `@sentry/nestjs` y `@sentry/node` como dependencies | low |

### users-ms

| File | Action | Reason | Risk |
|------|--------|--------|------|
| `users-ms/src/instrument.ts` | create | Side-effect: `initSentry('users-ms', envs.sentryDsn)` | low |
| `users-ms/src/main.ts` | modify | `import './instrument';` como primera línea | med |
| `users-ms/src/config/envs.ts` | modify | Agregar `SENTRY_DSN`, `SENTRY_TRACES_SAMPLE_RATE`, `SENTRY_DEV_VERIFY` | low |
| `users-ms/package.json` | modify | Agregar `@sentry/node` | low |

### events-ms

| File | Action | Reason | Risk |
|------|--------|--------|------|
| `events-ms/src/instrument.ts` | create | Side-effect: `initSentry('events-ms', envs.sentryDsn)` | low |
| `events-ms/src/main.ts` | modify | `import './instrument';` como primera línea | med |
| `events-ms/src/config/envs.ts` | modify | Agregar `SENTRY_DSN`, `SENTRY_TRACES_SAMPLE_RATE`, `SENTRY_DEV_VERIFY` | low |
| `events-ms/package.json` | modify | Agregar `@sentry/node` | low |

### vehicles-ms

| File | Action | Reason | Risk |
|------|--------|--------|------|
| `vehicles-ms/src/instrument.ts` | create | Side-effect: `initSentry('vehicles-ms', envs.sentryDsn)` | low |
| `vehicles-ms/src/main.ts` | modify | `import './instrument';` como primera línea | med |
| `vehicles-ms/src/config/envs.ts` | modify | Agregar `SENTRY_DSN`, `SENTRY_TRACES_SAMPLE_RATE`, `SENTRY_DEV_VERIFY` | low |
| `vehicles-ms/package.json` | modify | Agregar `@sentry/node` | low |

### maintenances-ms

| File | Action | Reason | Risk |
|------|--------|--------|------|
| `maintenances-ms/src/instrument.ts` | create | Side-effect: `initSentry('maintenances-ms', envs.sentryDsn)` | low |
| `maintenances-ms/src/main.ts` | modify | `import './instrument';` como primera línea | med |
| `maintenances-ms/src/config/envs.ts` | modify | Agregar `SENTRY_DSN`, `SENTRY_TRACES_SAMPLE_RATE`, `SENTRY_DEV_VERIFY` | low |
| `maintenances-ms/package.json` | modify | Agregar `@sentry/node` | low |

### notifications-ms

| File | Action | Reason | Risk |
|------|--------|--------|------|
| `notifications-ms/src/instrument.ts` | create | Side-effect: `initSentry('notifications-ms', envs.sentryDsn)` | low |
| `notifications-ms/src/main.ts` | modify | `import './instrument';` como primera línea | med |
| `notifications-ms/src/config/envs.ts` | modify | Agregar `SENTRY_DSN`, `SENTRY_TRACES_SAMPLE_RATE`, `SENTRY_DEV_VERIFY` | low |
| `notifications-ms/package.json` | modify | Agregar `@sentry/node` | low |

### Tests backend

| File | Action | Reason | Risk |
|------|--------|--------|------|
| `rideglory-common-lib/src/sentry/pii-filter.spec.ts` | create | Test `beforeSend` y `beforeBreadcrumb` con cada campo de `PII_SENSITIVE_FIELDS`; verifica que `captureException` no se llame para 4xx | low |
| `rideglory-common-lib/src/filters/rpc-all-exceptions.filter.spec.ts` | create | Test: `captureException` llamado para status >= 500; `Sentry.logger.warn` llamado para 400/404; flujo de control re-throw intacto | low |
| `api-gateway/src/common/exceptions/rpc-custom-exception.filter.spec.ts` | create | Misma batería que common-lib filter; verifica tag `service: 'api-gateway'` y `traceId` en `extra` | low |
| `api-gateway/src/instrument.spec.ts` | create | Smoke test: con `NODE_ENV !== 'production'` y sin `SENTRY_DEV_VERIFY`, `Sentry.init` no se llama | low |

---

## Contratos (rideglory-api internos)

Esta fase es **100% interna al backend**. No hay contratos nuevos expuestos a Flutter/HTTP. El contrato de respuesta HTTP del gateway hacia Flutter se mantiene intacto:

```
{ statusCode: number, message: string | string[], traceId?: string }
```

El header `x-trace-id` sigue siendo el mismo campo de Fase 1. Ningún campo nuevo en respuestas de error.

La única adición al envelope TCP `_meta` de Fase 1 es **cero cambios** — `traceId` ya viaja en `data._meta.traceId` por `TracingSerializer`/`TracingDeserializer`. Los filtros de los MS leen `traceId` de CLS (ya sembrado por `ClsRpcInterceptor`) para incluirlo en el structured log 4xx y en el `captureException` context.

---

## Datos / Migraciones

**No hay migraciones de Prisma ni cambios de schema.** Esta fase es pure observability — no toca ninguna tabla.

Ver `docs/exec-runs/backend-errores-5xx-sentry/analysis/MIGRATION_PLAN.md`: N/A (no se crea).

---

## Env deltas

Ver `docs/exec-runs/backend-errores-5xx-sentry/analysis/ENV_DELTA.md`.

Resumen:

| Variable | Servicios | Tipo joi | Descripción |
|----------|-----------|----------|-------------|
| `SENTRY_DSN` | ×6 (todos) | `string().uri().optional()` | DSN del proyecto Sentry único; ausente en dev |
| `SENTRY_TRACES_SAMPLE_RATE` | ×6 | `number().min(0).max(1).optional()` | Default `0.1` en prod. Controla volumen de traces |
| `SENTRY_DEV_VERIFY` | ×6 | `string().optional()` | Palanca temporal. `'true'` activa Sentry fuera de `NODE_ENV=production`. Eliminar al cerrar fases Sentry |

Las 3 vars son opcionales en joi — los servicios arrancan sin ellas (dev local sin DSN).

---

## Riesgos

| ID | Riesgo | Probabilidad | Impacto | Mitigación |
|----|--------|-------------|---------|-----------|
| R1 | `import './instrument'` colocado DESPUÉS de `import 'dotenv/config'` → Sentry no parchea NestJS correctamente | Media | Alto | Lint rule / code review explícito: `instrument` ANTES de cualquier otro import |
| R2 | Rebuild de common-lib no ejecutado antes de instalar en MS → `MODULE_NOT_FOUND` en arranque | Media | Alto | Documentado en gotchas; el backend agent debe seguir la secuencia: `npm run build` en common-lib → reinstalar en cada MS |
| R3 | `captureException` en filtros async → Sentry SDK dropea el evento si el proceso termina antes del flush | Baja | Medio | Agregar `await Sentry.flush(2000)` en el handler global de signals (`SIGTERM`) en `main.ts` de cada servicio |
| R4 | PII escapando por `exception.message` que incluye un email de usuario | Media | Alto | `beforeSend` debe scrubear `event.exception.values[].value` además de `extra`/`contexts`; cubierto por test |
| R5 | `@sentry/nestjs` en api-gateway agrega auto-instrumentation que modifica request/response y rompe shape hacia Flutter | Baja | Alto | Revisar que `SentryModule.forRoot()` no se importe en `app.module.ts`; la integración HTTP es via `instrument.ts` puro, no via `APP_FILTER` de Sentry |
| R6 | `Sentry.logger.warn` para 4xx consume structured logs quota (5 GB/mes) si hay spam de 4xx | Baja | Medio | `tracesSampleRate` + `beforeSendLog` puede muestrear logs si se acerca al límite |
| R7 | Palanca `SENTRY_DEV_VERIFY` olvidada en producción | Baja | Bajo | No es peligroso (solo activa Sentry antes de `NODE_ENV=production`); PR de cierre de fases Sentry la elimina |

---

## Orden de implementación

1. **rideglory-common-lib** — nueva carpeta `src/sentry/` (`init-sentry.ts`, `pii-filter.ts`, `sentry.module.ts`, `index.ts`); modificar `rpc-all-exceptions.filter.ts`; agregar `@sentry/node` peerDep; `npm run build`
2. **Reinstalar common-lib** en los 6 servicios (`pnpm install` o `npm install` según el workspace)
3. **api-gateway** — `instrument.ts`, modificar `main.ts`, `rpc-custom-exception.filter.ts`, `config/envs.ts`, `package.json` (agregar `@sentry/nestjs`)
4. **users-ms** — `instrument.ts`, `main.ts`, `config/envs.ts`, `package.json`
5. **events-ms** — ídem
6. **vehicles-ms** — ídem
7. **maintenances-ms** — ídem
8. **notifications-ms** — ídem
9. **Tests** — `pii-filter.spec.ts`, `rpc-all-exceptions.filter.spec.ts` (common-lib), `rpc-custom-exception.filter.spec.ts` + `instrument.spec.ts` (api-gateway)
10. **Smoke test de arranque** — los 6 servicios sin `SENTRY_DSN`

---

## Superficie de regresión

- `RpcCustomExceptionFilter` (api-gateway): único punto de salida HTTP hacia Flutter. El shape `{ statusCode, message, traceId? }` y el header `x-trace-id` deben permanecer intactos. Cualquier cambio en `normalizeError()` o en el `response.status().json()` final es regresión.
- `RpcAllExceptionsFilter` (common-lib): compartido por los 5 MS. Un cambio incorrecto en el `catch()` puede silenciar excepciones o cambiar el `RpcException` que el gateway recibe.
- Orden de imports en `main.ts` ×6: cambio de una línea con alto impacto (Sentry no inicializa si está en posición incorrecta).
- Rebuild de common-lib: si el dist queda desactualizado, los MS importan la versión anterior sin Sentry → errores silenciados.

---

## Fuera de alcance

- Cambios en `@rideglory/contracts` (DTOs, message patterns)
- Migraciones de Prisma
- Sentry en Flutter (Fase 3)
- Tracing del canal WebSocket `/tracking/ws` (limitación documentada: el WsAdapter no participa del HTTP middleware CLS, y la correlación traceId en WS requiere un mecanismo propio fuera de esta fase)
- Dashboards / alertas en consola Sentry
- Creación de filtros de excepción nuevos (solo extensión de los existentes)

---

## Flutter — stand-down

Esta fase no toca código Flutter. No hay cambios en `lib/`. El flutter agent no ejecuta.
