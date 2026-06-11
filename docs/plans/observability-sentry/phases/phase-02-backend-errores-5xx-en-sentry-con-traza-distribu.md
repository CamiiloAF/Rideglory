# Fase 2 — Backend: errores 5xx en Sentry con traza distribuida

- **Generado (UTC):** 2026-06-10T22:20:13Z
- **Plan:** observability-sentry
- **Fase id:** 2 | **Depende de:** [1]
- **Repo afectado:** backend `/Users/cami/Developer/Personal/rideglory-api` (6 servicios + `rideglory-common-lib`)
- **Nivel rg-exec recomendado:** **full**

## Objetivo

El equipo ve crashes y errores **5xx** del backend en **Sentry como *error events* (con alerta)**, correlacionados por `traceId` y por el tag `service`. Los **4xx** se envían a Sentry como **structured logs** (contexto ligado al `traceId`), **no** como *error events*: aparecen para investigar pero **no disparan alerta ni consumen la cuota de errores** (5k/mes); usan la cuota de Sentry Logs (5 GB/mes). La instrumentación está activa **solo en producción** (`NODE_ENV === 'production'`), no rompe el arranque de dev local sin DSN, y nunca filtra PII ni secretos.

## Alcance (entra / no entra)

### Entra
- `instrument.ts` por servicio (6) con `Sentry.init(...)`, **importado en la primera línea** de cada `main.ts`.
- `SentryModule.forRoot()` registrado en el `AppModule` de cada servicio, **gated** por `NODE_ENV === 'production'` (DSN vacío / `enabled: false` en dev).
- **Extender los filtros existentes** (`RpcCustomExceptionFilter` en gateway, `RpcAllExceptionsFilter` en common-lib): `status >= 500` → `Sentry.captureException(...)` (*error event*, alerta); `status` 4xx → `Sentry.logger.warn(...)` (structured log con `traceId`/`service`/ruta/status), **no** *error event*. Los 4xx también se siguen logueando por pino (Fase 1).
- `enableLogs: true` en `Sentry.init(...)` para habilitar los structured logs de los 4xx.
- Reuso del envelope `_meta` de la Fase 1 para transportar `sentry-trace` / `baggage` sobre TCP y cerrar el trace HTTP↔TCP.
- **Un solo proyecto Sentry** con tag `service` (gateway / users-ms / events-ms / vehicles-ms / maintenances-ms / notifications-ms). Decisión cerrada.
- Añadir `NODE_ENV` y `SENTRY_DSN` (opcional en joi) a los **6** `config/envs.ts`.
- `beforeSend` / `beforeBreadcrumb` con filtrado PII reusando la denylist centralizada de la Fase 1.
- **Abstracción en `rideglory-common-lib`** de la tríada serializer/deserializer/cls (de la Fase 1) + el bootstrap de Sentry (`instrument` helper + `SentryModule` wrapper + esquema joi `NODE_ENV`/`SENTRY_DSN`), registrada ×6, como **criterio de aceptación**. Rebuild + reinstalación disciplinada en los 6 servicios.
- `tracesSampleRate` configurable por env (decisión de sampling cerrada en el gate previo a esta fase).

### No entra
- Cambios en `@rideglory/contracts`, DTOs o los ~56 message patterns (el `traceId`/`sentry-trace` viaja en el envelope `_meta`, fuera del payload).
- Migraciones de datos / Prisma.
- Sentry en Flutter (Fase 3) y cualquier cambio en el cliente móvil.
- Tracing del canal WebSocket `/tracking/ws` (best-effort, fuera del alcance core; solo documentar la limitación, ya declarada en Fase 1).
- Crear filtros de excepción nuevos (se extienden los dos existentes).
- Dashboards / alertas en la consola Sentry (config de proyecto, no de código).

## Que se debe hacer (pasos concretos y ordenados)

> Gate previo (cerrar antes de abrir el `rg-exec`): **sampling** (`tracesSampleRate` por env) y **gestión de DSN backend** (secret manager / `.env`, nunca commiteado). La denylist PII ya quedó cerrada y centralizada en Fase 1.

1. **Config (joi) ×6.** En cada `*/src/config/envs.ts` añadir a la interfaz `EnvVars`, al `envSchema` y al objeto `envs` exportado: `NODE_ENV` (`joi.string().valid('development','production','test').default('development')`) y `SENTRY_DSN` (`joi.string().uri().optional()`, vacío permitido en dev). No romper el arranque sin DSN.

2. **Helper de Sentry en `rideglory-common-lib`.** Crear en `rideglory-common-lib/src/`:
   - Un helper `initSentry({ dsn, environment, service, tracesSampleRate, release? })` que llame `Sentry.init(...)` con: `enabled: environment === 'production' && !!dsn`, `enableLogs: true` (structured logs para los 4xx), `tracesSampleRate` desde env, `initialScope: { tags: { service } }`, y `beforeSend`/`beforeSendLog`/`beforeBreadcrumb` que apliquen la denylist PII compartida (Fase 1) sobre `request`, `extra`, `contexts`, `breadcrumbs` y los atributos de log (Authorization, ID token, password, email, teléfono, SOAT, placa, VIN). El helper es **no-op efectivo en dev/test** (no envía).
   - Un wrapper para registrar `SentryModule.forRoot()` (o reexportar el del SDK NestJS) más la integración de captura para los filtros.
   - Exportar todo por el barrel `index.ts` de la lib.

3. **`instrument.ts` ×6.** Crear `*/src/instrument.ts` que importe el helper y ejecute `initSentry(...)` con el `service` correspondiente (`api-gateway`, `users-ms`, …), leyendo `SENTRY_DSN`/`NODE_ENV`/`tracesSampleRate` de `envs`. Debe ejecutarse al importarse (efecto de módulo), sin depender de Nest.

4. **Import en la primera línea de cada `main.ts` ×6.** Insertar `import './instrument';` **como primera línea**, antes de `import 'dotenv/config'` o, si `instrument.ts` necesita las envs ya cargadas, garantizar que `instrument.ts` haga su propio `import 'dotenv/config'` en su primera línea y luego se importe primero en `main.ts`. El orden de carga es crítico (R7): la instrumentación debe cargar antes que `@nestjs/core` y los módulos de la app.

5. **Registrar `SentryModule.forRoot()` en cada `AppModule`** (gateway + 5 MS), gated por `NODE_ENV === 'production'`. Reusar el wrapper de common-lib para no divergir.

6. **Extender `RpcCustomExceptionFilter` (gateway).** En `api-gateway/src/common/exceptions/rpc-custom-exception.filter.ts`: tras `normalizeError`, si `normalized.status >= 500`, además de `this.logger.error(...)`, `Sentry.captureException(...)` con el scope del request (tag `service: 'api-gateway'`, `traceId` desde el CLS de Fase 1, ruta/método). Si `normalized.status` es 4xx, emitir `Sentry.logger.warn(...)` con `{ traceId, service, route, method, status }` (structured log, **no** *error event*) además del log pino. Mantener intacta la respuesta JSON `{ statusCode, message }` (más el `traceId`/header de Fase 1).

7. **Extender `RpcAllExceptionsFilter` (common-lib).** En `rideglory-common-lib/src/filters/rpc-all-exceptions.filter.ts`: en la rama de excepción no controlada (status efectivo `>= 500`, p.ej. el `INTERNAL_SERVER_ERROR` final y errores de infra como Prisma), `Sentry.captureException(...)` con tag `service` del MS y el `traceId` extraído del `_meta` (sembrado en CLS por el deserializer de Fase 1). Las `RpcException` de negocio que normalizan a 4xx se emiten como `Sentry.logger.warn(...)` (structured log con `traceId`/`service`/status), **no** como *error event*. No cambiar el contrato de re-lanzado (`RpcException` con `{ status, message }`).

8. **Cerrar el trace HTTP↔TCP.** Confirmar que el serializer (gateway) inyecta `sentry-trace`/`baggage` en `_meta` (canal extensible diseñado en Fase 1) y que el deserializer del MS los usa para continuar el span de Sentry. Si el SDK no continúa automático sobre TCP, derivar el span/trace del `traceId` propio para que el evento Sentry del MS comparta `traceId` con el del gateway.

9. **Rebuild + reinstalación disciplinada de `rideglory-common-lib`.** En la lib: `npm run build`. Luego en cada MS que la consume reinstalar la lib (gotcha de memoria: `MODULE_NOT_FOUND` si no se reconstruye/reinstala). Verificar que los 6 servicios arrancan en dev sin DSN.

10. **Verificación de instrumentación.** Lanzar un error de prueba 5xx por servicio (en prod-like con DSN de staging) y confirmar: evento en Sentry, tag `service` correcto, `traceId` presente y compartido gateway↔MS, y **ausencia** del evento para un 4xx de negocio.

## Archivos a crear/modificar (rutas reales, una linea de "que cambia")

### Crear
- `rideglory-api/rideglory-common-lib/src/sentry/init-sentry.ts` — helper `initSentry(...)` con gating prod, tag `service`, `tracesSampleRate` y `beforeSend`/`beforeBreadcrumb` PII.
- `rideglory-api/rideglory-common-lib/src/sentry/sentry.module.ts` — wrapper de `SentryModule.forRoot()` reutilizable ×6 (o reexport gated).
- `rideglory-api/api-gateway/src/instrument.ts` — `initSentry` para `service: 'api-gateway'`.
- `rideglory-api/users-ms/src/instrument.ts` — `initSentry` para `service: 'users-ms'`.
- `rideglory-api/events-ms/src/instrument.ts` — `initSentry` para `service: 'events-ms'`.
- `rideglory-api/vehicles-ms/src/instrument.ts` — `initSentry` para `service: 'vehicles-ms'`.
- `rideglory-api/maintenances-ms/src/instrument.ts` — `initSentry` para `service: 'maintenances-ms'`.
- `rideglory-api/notifications-ms/src/instrument.ts` — `initSentry` para `service: 'notifications-ms'`.

### Modificar
- `rideglory-api/rideglory-common-lib/src/index.ts` — exportar el helper Sentry y el wrapper del módulo.
- `rideglory-api/rideglory-common-lib/src/filters/rpc-all-exceptions.filter.ts` — `captureException` para `>= 500` con tag `service` + `traceId`; 4xx vía `Sentry.logger.warn` (structured log) + pino.
- `rideglory-api/api-gateway/src/common/exceptions/rpc-custom-exception.filter.ts` — `captureException` para `normalized.status >= 500` con scope/`traceId`; 4xx vía `Sentry.logger.warn` (structured log) + pino.
- `rideglory-api/api-gateway/src/main.ts` — `import './instrument';` como primera línea.
- `rideglory-api/users-ms/src/main.ts` — `import './instrument';` como primera línea.
- `rideglory-api/events-ms/src/main.ts` — `import './instrument';` como primera línea.
- `rideglory-api/vehicles-ms/src/main.ts` — `import './instrument';` como primera línea.
- `rideglory-api/maintenances-ms/src/main.ts` — `import './instrument';` como primera línea.
- `rideglory-api/notifications-ms/src/main.ts` — `import './instrument';` como primera línea.
- `rideglory-api/api-gateway/src/app.module.ts` — registrar `SentryModule` gated.
- `rideglory-api/{users,events,vehicles,maintenances,notifications}-ms/src/app.module.ts` — registrar `SentryModule` gated (×5).
- `rideglory-api/api-gateway/src/config/envs.ts` — añadir `NODE_ENV` y `SENTRY_DSN` (opcional) a interfaz, schema y `envs`.
- `rideglory-api/{users,events,vehicles,maintenances,notifications}-ms/src/config/envs.ts` — añadir `NODE_ENV` y `SENTRY_DSN` (opcional) (×5).
- `rideglory-api/*/package.json` — añadir dependencia del SDK Sentry NestJS (`@sentry/nestjs` / `@sentry/node`) donde aplique; common-lib expone la integración.
- `rideglory-api/docs/` (doc del servicio correspondiente) — documentar gating prod, tag `service`, filtrado 4xx y la limitación de tracing WS (best-effort).

## Contratos / API rideglory-api

**Ninguno que rompa compatibilidad.**
- `@rideglory/contracts` (DTOs / ~56 message patterns): **sin cambios** — el `traceId`/`sentry-trace`/`baggage` viaja en el envelope `_meta` del transporte, no en el payload.
- HTTP gateway hacia Flutter: aditivo y ya cubierto en Fase 1 (`x-trace-id` en respuesta, `traceId` en cuerpo de error). Fase 2 no altera el shape de la respuesta de error (`{ statusCode, message }`).
- `rideglory-common-lib`: **nueva superficie compartida** (helper Sentry + wrapper de módulo + filtro extendido). Consumida por los 6 servicios. Requiere rebuild + reinstalación (gotcha de memoria).

## Cambios de datos / migraciones

**Ninguno.** La observabilidad no toca el esquema de datos ni Prisma.

## Criterios de aceptacion (numerados, observables, testeables)

1. Con `NODE_ENV=production` y `SENTRY_DSN` válido, un error que normaliza a `status >= 500` en el gateway produce **un** evento en Sentry con tag `service: api-gateway` y el `traceId` del request.
2. Con `NODE_ENV=production` y `SENTRY_DSN` válido, un error no controlado (`>= 500`) en cualquier MS produce **un** evento en Sentry con el tag `service` correcto (`users-ms`, etc.) y el `traceId` propagado por `_meta`.
3. Un request que atraviesa gateway→MS y falla con 5xx genera eventos cuyo `traceId` es **el mismo** en gateway y MS (trace HTTP↔TCP cerrado).
4. Un error de negocio 4xx (p.ej. validación, `BadRequest`, `NotFound`) **no** genera *error event* en Sentry (no crea *issue* ni alerta) pero **sí** produce un structured log en Sentry (`Sentry.logger.warn`) con `traceId`/`service`/status, y se loguea por pino (Fase 1).
5. Con `NODE_ENV !== 'production'` o `SENTRY_DSN` vacío, **ningún** servicio envía eventos a Sentry, y los 6 servicios arrancan correctamente en dev local.
6. `import './instrument';` es la **primera línea** de los 6 `main.ts`; un error de prueba confirma que la instrumentación NestJS está activa (no silenciosa) por servicio.
7. Los 6 `config/envs.ts` validan `NODE_ENV` y `SENTRY_DSN` (este último opcional) sin romper el arranque cuando faltan en dev.
8. Ningún evento Sentry (campos `request`, `extra`, `contexts`, `breadcrumbs`) contiene PII de la denylist (Authorization, ID token, password, email, teléfono, SOAT, placa, VIN), verificado por test sobre `beforeSend`/`beforeBreadcrumb`.
9. La tríada serializer/deserializer/cls + el bootstrap de Sentry viven en `rideglory-common-lib` y se registran ×6 sin copy-paste divergente; tras `npm run build` + reinstalación los 6 servicios compilan y arrancan.
10. No hay cambios en `@rideglory/contracts`, en los message patterns ni en el esquema de datos (diff vacío en esas superficies).
11. `Sentry.captureException` (*error event*) solo dispara para `>= 500`: un test unitario de cada filtro verifica que se llama al captador para 500 y **no** para 400/404. Para 400/404 se verifica que se llama a `Sentry.logger.warn` (structured log) y **no** a `captureException`.
12. Los attributes de los structured logs de 4xx (`Sentry.logger.warn`) tampoco contienen PII de la denylist (verificado por `beforeSendLog`).

## Pruebas (unitarias/widget/integracion)

- **Unitarias filtro gateway** (`rpc-custom-exception.filter.spec.ts`): para `status >= 500` se invoca `captureException` (mock); para 4xx **no** se invoca `captureException` pero **sí** `Sentry.logger.warn`; la respuesta JSON sigue siendo `{ statusCode, message }`.
- **Unitarias filtro common-lib** (`rpc-all-exceptions.filter.spec.ts`): excepción no controlada (`>= 500`) → `captureException` con tag `service` y `traceId`; `RpcException` de negocio 4xx → `Sentry.logger.warn` (no `captureException`); re-lanzado `RpcException` intacto.
- **Unitarias `beforeSend`/`beforeBreadcrumb`** (PII): dado un evento con campos de la denylist en `request`/`extra`/`breadcrumbs`, el resultado los redacta/elimina; test que **falla** si un campo de la denylist pasa sin redactar (reuso de la fuente compartida de Fase 1).
- **Unitarias `initSentry` (gating):** con `environment !== 'production'` o DSN vacío → `enabled: false` (no envía); con prod + DSN → `enabled: true`, tag `service` y `tracesSampleRate` aplicados.
- **Integración por servicio (prod-like, DSN de staging):** lanzar 5xx de prueba y 4xx de negocio; confirmar evento solo para el 5xx, tag `service`, y `traceId` compartido gateway↔MS (cubre criterios 1–4).
- **Arranque dev:** smoke de que los 6 servicios levantan sin `SENTRY_DSN` (criterio 5/7).

## Riesgos y mitigaciones

- **R5 — Divergencia ×6 del patrón** (Media): abstraer en `rideglory-common-lib` como criterio de aceptación; rebuild + reinstalación disciplinada en cada MS.
- **R6 — Cuota free Sentry (5k *errores*/mes)** (Media): los 4xx van como structured logs (cuota de logs 5 GB, aparte), no como *error events*; `tracesSampleRate` por env; un solo proyecto con tag `service`. Vigilar el volumen de logs 4xx para no agotar los 5 GB.
- **R7 — Orden de import de `instrument.ts`** (Baja): `import './instrument';` como primera línea de cada `main.ts`; verificar con error de prueba por servicio.
- **R8 — Tracing HTTP↔TCP no automático** (Media): transportar `sentry-trace`/`baggage` en el envelope `_meta` extensible de Fase 1; derivar span del `traceId` propio si el SDK no continúa sobre TCP.
- **R3 — Fuga de PII en eventos Sentry** (Alta): `beforeSend`/`beforeBreadcrumb` con la denylist centralizada + test que falla ante fuga; revisión explícita antes de habilitar prod.
- **Gotcha rebuild common-lib** (`MODULE_NOT_FOUND`): `npm run build` en la lib + reinstalar en los 6 MS antes de validar; smoke de arranque.
- **Romper dev sin DSN** (Media): `SENTRY_DSN` opcional en joi + gating `NODE_ENV === 'production'`; smoke de arranque de los 6 servicios sin DSN.

## Dependencias (fases prerequisito y por que)

- **Fase 1 (prerequisito duro):** Fase 2 reusa (a) el `traceId` distribuido por TCP vía serializer/deserializer custom + `nestjs-cls`, (b) el envelope `_meta` extensible para transportar `sentry-trace`/`baggage`, y (c) la denylist PII centralizada para `beforeSend`. Sin la base de correlación de Fase 1 no hay `traceId` compartido entre gateway y MS ni canal para el tracing distribuido. La abstracción en `rideglory-common-lib` extiende la superficie creada en Fase 1.

## Ejecucion recomendada (nivel rg-exec: full)

**Por qué full:** toca el manejo global de errores de los 6 servicios extendiendo los filtros de excepciones existentes (`RpcCustomExceptionFilter`, `RpcAllExceptionsFilter`), filtrado PII en `beforeSend`, abstracción ×6 en `rideglory-common-lib` como criterio de aceptación y gating prod. Es cross-cutting + seguridad/PII + alto blast radius: la divergencia entre los 6 MS o una fuga de PII serían costosas. Depende del envelope de la Fase 1, así que el auditor Opus debe verificar la correcta reutilización del canal `_meta` y la ausencia de regresiones en el flujo de errores.
