# Fase 1 — Backend: traceId distribuido por TCP + logs estructurados sin PII

- **Generado (UTC):** 2026-06-10T22:23:54Z
- **Plan:** observability-sentry
- **Repo objetivo:** backend `/Users/cami/Developer/Personal/rideglory-api` (Flutter solo consume el header `x-trace-id`, sin cambios en esta fase)
- **dependsOn:** []
- **Nivel rg-exec recomendado:** full

## Objetivo

Operación y soporte pueden seguir un request por su `traceId` desde el gateway HTTP hasta cada microservicio TCP, con logs estructurados (JSON en prod, legibles en dev) y **sin PII ni secretos**. El `traceId` se genera (o se continúa desde `x-request-id`/`sentry-trace` entrante) en el gateway, viaja por TCP en un envelope `_meta` extensible sin tocar `.send()`, DTOs ni los ~56 message patterns, y vuelve al cliente por el header de respuesta `x-trace-id`. Sin Sentry todavía: esta fase deja lista la base de correlación que consumen las Fases 2 y 3.

## Alcance (entra / no entra)

**Entra:**
- `nestjs-pino` en los 6 servicios (gateway + `users-ms`, `events-ms`, `vehicles-ms`, `maintenances-ms`, `notifications-ms`): `pino-pretty` en dev, JSON en prod.
- Reemplazo de `HttpLoggerMiddleware` por el logging req/resp de pino + un interceptor de gateway con método, ruta, status, latencia y `traceId`.
- `nestjs-cls` en el gateway: genera/continúa el `traceId` y lo guarda en CLS por request.
- **Serializer** custom del `ClientProxy` (gateway): inyecta el mapa `_meta` (con `traceId`) en el envelope TCP, leyéndolo del CLS.
- **Deserializer** custom + interceptor en cada MS: extrae `_meta.traceId`, lo siembra en el CLS del MS para que pino lo emita por línea.
- Redacción PII en **dos capas**: `redact` nativo de pino (por path) + interceptor request/response con allowlist. Denylist centralizada con test.
- Header de respuesta `x-trace-id` desde el gateway + `traceId` en el cuerpo de error (nunca como copy visible).
- Abstracción de la tríada serializer/deserializer/cls-setup + denylist PII + helpers de pino en `rideglory-common-lib` (nuevo subdirectorio `observability/`).

**No entra:**
- Sentry (instrument.ts, SentryModule, captura de errores) → Fase 2.
- Transporte de `sentry-trace`/`baggage` en `_meta` → el envelope se diseña extensible **ahora**, pero el cableado de Sentry es Fase 2.
- Cambios en Flutter (consumo del header `x-trace-id`) → Fase 3.
- Tracing del canal WebSocket `/tracking/ws` → best-effort, fuera de alcance core (solo documentar la limitación).
- Modificar `@rideglory/contracts`, los DTOs de payload o las firmas de los message patterns.
- `NODE_ENV`/`SENTRY_DSN` en joi → Fase 2.

## Que se debe hacer (pasos concretos y ordenados)

1. **Cerrar el gate previo (decisión #5):** fijar la allowlist/denylist exacta de PII como fuente compartida con test antes de implementar. Denylist confirmada por el intake: `Authorization`, ID token, `password`, `email`, teléfono, SOAT, placa, VIN (y sus variantes de nombre de campo). Documentarla en `rideglory-common-lib/src/observability/`.

2. **Dependencias:** añadir `nestjs-pino`, `pino`, `pino-pretty`, `nestjs-cls` a los servicios que las usan (gateway todas; cada MS al menos `nestjs-pino` + `nestjs-cls`). Recordar el gotcha: tras tocar `rideglory-common-lib`, `npm run build` en la lib + reinstalar/`npm install` en cada MS consumidor.

3. **Diseñar el envelope `_meta` como mapa extensible** (no un string suelto): `interface TcpMeta { traceId: string; [key: string]: unknown }`. Esto permite que la Fase 2 añada `sentry-trace`/`baggage` sin rehacer el serializer. Definirlo en `rideglory-common-lib/src/observability/`.

4. **Gateway — CLS + traceId:** registrar `ClsModule.forRoot` con `setup` que, por cada request HTTP, genere un `traceId` nuevo o continúe el `x-request-id`/`sentry-trace` entrante si llega, y lo guarde en CLS. Probar primero **un solo MS extremo a extremo** (recomendado: `users-ms` vía `home.module.ts` o `users.module.ts`) antes de replicar ×6 (mitiga R1).

5. **Gateway — pino:** reemplazar `HttpLoggerMiddleware` por `LoggerModule.forRoot` de `nestjs-pino` (`pino-pretty` dev, JSON prod), con `genReqId` que use/continúe el `traceId` del CLS y `customProps` que adjunte el `traceId` a cada línea. Quitar el `consumer.apply(HttpLoggerMiddleware)` de `app.module.ts`. Añadir un interceptor que loguee método, ruta, status, latencia y `traceId`.

6. **Gateway — Serializer custom en cada `ClientsModule`:** en los **9 módulos** que registran `ClientsModule` (ver lista exacta en la sección de archivos), añadir la opción `serializer` al cliente TCP para que lea el `traceId` del CLS e inyecte el envelope `_meta`. El serializer vive en `rideglory-common-lib/src/observability/` y se reutiliza. **Sin tocar ninguna llamada `.send()` ni DTO.** El módulo del scheduler es `api-gateway/src/scheduler/notification-scheduler.module.ts`.

7. **MS — Deserializer + interceptor:** en cada MS, registrar `ClsModule` y configurar el microservicio TCP con el `deserializer` custom que extrae `_meta.traceId`; un interceptor RPC lo siembra en el CLS del MS por mensaje. Conectar `nestjs-pino` en cada MS para que emita el `traceId` por línea. Aplicar al MS piloto primero, validar, luego replicar.

8. **Redacción PII (dos capas):** (a) configurar `redact` de pino con los paths de la denylist; (b) interceptor request/response con allowlist que filtre cuerpos antes de loguear. Ambas capas consumen la denylist centralizada.

9. **Header al cliente:** en el gateway, escribir el header de respuesta `x-trace-id` con el `traceId` del CLS (interceptor o filtro), y asegurar que el cuerpo de error de `RpcCustomExceptionFilter` incluya `traceId`. **Nunca** exponerlo como copy visible; es metadato técnico.

10. **Abstracción en common-lib:** mover serializer/deserializer/cls-setup/denylist/helpers de pino a `rideglory-common-lib/src/observability/` y exportarlos desde `index.ts` (`export * from './observability'`). Verificar que cada MS y el gateway consuman desde la lib, no copias locales (mitiga R5).

11. **Validación end-to-end:** disparar un request HTTP y verificar que el `traceId` aparece idéntico en las líneas del gateway y del MS, que vuelve por `x-trace-id`, y que ningún campo de la denylist aparece sin redactar.

## Archivos a crear/modificar (rutas reales, una linea de "que cambia")

### Crear (compartido) — `rideglory-common-lib`
- `rideglory-common-lib/src/observability/index.ts` — barrel del nuevo subdirectorio (junto a los existentes `filters/`, `interfaces/`, `dto/`).
- `rideglory-common-lib/src/observability/tcp-meta.interface.ts` — `TcpMeta` (mapa extensible con `traceId`).
- `rideglory-common-lib/src/observability/trace-serializer.ts` — Serializer del `ClientProxy` que inyecta `_meta` desde el CLS.
- `rideglory-common-lib/src/observability/trace-deserializer.ts` — Deserializer que extrae `_meta` del envelope TCP.
- `rideglory-common-lib/src/observability/trace-cls.interceptor.ts` — interceptor RPC que siembra el `traceId` en el CLS del MS.
- `rideglory-common-lib/src/observability/pii-denylist.ts` — denylist PII central (Authorization, ID token, password, email, teléfono, SOAT, placa, VIN) + helper de redacción.
- `rideglory-common-lib/src/observability/pino.config.ts` — factory de opciones de pino (pretty dev / JSON prod, `redact`, `genReqId`, `customProps`) reutilizable.
- `rideglory-common-lib/src/index.ts` — **modificar:** añadir `export * from './observability';` junto a los `filters`/`interfaces`/`dto` existentes.

### Modificar (gateway) — registro de Serializer + CLS + pino
- `api-gateway/src/main.ts` — usar el logger de `nestjs-pino` (`app.useLogger`), asegurar `x-trace-id` en respuestas; sin `instrument.ts` aún.
- `api-gateway/src/app.module.ts` — quitar `HttpLoggerMiddleware`; añadir `ClsModule.forRoot` (gen/continúa `traceId`) + `LoggerModule.forRoot` de pino + interceptor de logging req/resp.
- `api-gateway/src/common/middleware/http-logger.middleware.ts` — **eliminar** (sustituido por pino + interceptor).
- `api-gateway/src/common/exceptions/rpc-custom-exception.filter.ts` — incluir `traceId` (desde CLS) en el cuerpo de error y header `x-trace-id`; loguear vía pino.
- `api-gateway/src/home/home.module.ts` — añadir `serializer` custom al/los `ClientsModule.register`.
- `api-gateway/src/users/users.module.ts` — añadir `serializer` custom al/los `ClientsModule.register`.
- `api-gateway/src/events/events.module.ts` — añadir `serializer` custom al/los `ClientsModule.register`.
- `api-gateway/src/vehicles/vehicles.module.ts` — añadir `serializer` custom al/los `ClientsModule.register`.
- `api-gateway/src/maintenances/maintenances.module.ts` — añadir `serializer` custom al/los `ClientsModule.register`.
- `api-gateway/src/tracking/tracking.module.ts` — añadir `serializer` custom al/los `ClientsModule.register`.
- `api-gateway/src/notifications/notifications.module.ts` — añadir `serializer` custom al/los `ClientsModule.register`.
- `api-gateway/src/registrations/registrations.module.ts` — añadir `serializer` custom al/los `ClientsModule.register`.
- `api-gateway/src/scheduler/notification-scheduler.module.ts` — añadir `serializer` custom al/los `ClientsModule.register` (ruta real anidada del scheduler).
- `api-gateway/package.json` — añadir `nestjs-pino`, `pino`, `pino-pretty`, `nestjs-cls`.

### Modificar (cada MS) — Deserializer + CLS + pino
- `users-ms/src/main.ts` — configurar `deserializer` custom en el microservicio TCP + `app.useLogger` de pino.
- `events-ms/src/main.ts` — idem.
- `vehicles-ms/src/main.ts` — idem.
- `maintenances-ms/src/main.ts` — idem.
- `notifications-ms/src/main.ts` — idem.
- `users-ms/src/app.module.ts` (y los `app.module.ts` de los otros 4 MS) — registrar `ClsModule` + `LoggerModule` de pino + `TraceClsInterceptor`.
- `users-ms/package.json` (y los `package.json` de los otros 4 MS) — añadir `nestjs-pino`, `pino`, `nestjs-cls`.

> Nota: el número exacto de clientes (`USERS_SERVICE`, `VEHICLES_SERVICE`, `EVENTS_SERVICE`, …) por módulo varía; el serializer se añade a cada cliente registrado dentro de cada `ClientsModule.register([...])`. Los 9 módulos listados son exactamente los que hoy registran `ClientsModule`.

## Contratos / API rideglory-api

- **`@rideglory/contracts` (DTOs/patterns):** ninguno. El `traceId` viaja en el envelope TCP `_meta`, fuera de los DTOs de payload; los ~56 message patterns conservan su firma. Evita el gotcha de rebuild de contracts.
- **HTTP gateway → cliente Flutter:** **aditivo y compatible hacia atrás.** Nuevo header de respuesta `x-trace-id`; el cuerpo de error añade el campo `traceId`. El gateway continúa `x-request-id`/`sentry-trace` entrante si llega. Flutter lo consume opcionalmente en Fase 3.
- **`rideglory-common-lib`:** nueva superficie compartida (`observability/`). Aplica el gotcha: `npm run build` en la lib + reinstalar en cada MS consumidor.

## Cambios de datos / migraciones

Ninguno. La observabilidad no toca el esquema Prisma ni datos persistidos.

## Criterios de aceptacion (numerados, observables, testeables)

1. Un request HTTP al gateway produce un `traceId` que aparece **idéntico** en al menos una línea de log del gateway y en al menos una línea de log del MS invocado.
2. Si el request entrante trae `x-request-id` (o `sentry-trace`), el `traceId` lo **continúa** en vez de generar uno nuevo; si no trae, genera uno.
3. La respuesta HTTP incluye el header `x-trace-id` con el mismo `traceId`; los cuerpos de error incluyen el campo `traceId`.
4. En dev los logs salen legibles (`pino-pretty`); en prod salen en JSON estructurado (una línea por evento).
5. Ningún campo de la denylist (`Authorization`, ID token, `password`, `email`, teléfono, SOAT, placa, VIN) aparece en claro en ninguna línea de log ni en el cuerpo de respuesta: queda redactado por las dos capas (pino `redact` + interceptor allowlist).
6. Los ~56 message patterns y los DTOs de `@rideglory/contracts` **no** cambian de firma; el diff no toca esos archivos.
7. El serializer/deserializer/cls-setup/denylist viven en `rideglory-common-lib/src/observability/` y se consumen desde la lib en gateway y MS (no hay copias divergentes); `index.ts` exporta `./observability`.
8. `HttpLoggerMiddleware` queda eliminado y no referenciado en `app.module.ts`.
9. El interceptor de logging del gateway emite método, ruta, status, latencia y `traceId` por request.
10. Sin Sentry: no hay `instrument.ts`, `SentryModule` ni dependencias `@sentry/*` introducidas en esta fase.
11. Cada servicio arranca correctamente con el logger de pino activo (humo de arranque ×6).

## Pruebas (unitarias/widget/integracion)

- **Unitaria — denylist PII:** test que recorre la denylist y falla si un campo sensible aparece sin redactar tras pasar por el helper de redacción; test que falla si se añade un campo sensible nuevo sin cubrirlo (guarda anti-regresión de R3).
- **Unitaria — serializer:** dado un `traceId` en el CLS, el envelope serializado contiene `_meta.traceId`; sin `traceId` en CLS, el envelope sigue siendo válido (no rompe `.send()`).
- **Unitaria — deserializer:** dado un envelope con `_meta.traceId`, lo extrae y lo deja disponible para sembrar en CLS; envelope sin `_meta` no rompe el flujo (backward-compatible).
- **Integración (MS piloto) — propagación end-to-end:** request HTTP → gateway → MS, asertando mismo `traceId` en logs de ambos y en el header `x-trace-id`. Ejecutar en el MS piloto antes de replicar ×6.
- **Integración — redacción:** request con un body que contenga campos de la denylist; asertar que los logs capturados no contienen los valores sensibles.
- **Humo de arranque:** cada uno de los 6 servicios levanta con pino sin errores de DI ni de import.

## Riesgos y mitigaciones

- **R1 — Propagación TCP del traceId (Media):** serializer/deserializer custom + CLS, sin tocar payloads/DTOs. Mitigación: probar un MS extremo a extremo antes de replicar ×6.
- **R3 — Fuga de PII/secretos (Alta):** redacción en dos capas (pino `redact` + interceptor allowlist) sobre denylist central con test que falla si falta un campo. Revisión explícita antes de habilitar prod.
- **R5 — Divergencia ×6 del patrón (Media):** abstraer la tríada + denylist en `rideglory-common-lib/src/observability/`; disciplina de `npm run build` + reinstalar en cada MS (gotcha de contracts/lib).
- **R8 — Tracing HTTP↔TCP no automático (Media, se materializa en Fase 2):** diseñar `_meta` como mapa extensible **ahora** para que Fase 2 transporte `sentry-trace`/`baggage` sin rehacer el serializer.
- **R10 — WS no correlacionado (Baja):** documentar `/tracking/ws` como best-effort fuera de alcance core; no bloquear.
- **Riesgo de build (lib):** olvidar reconstruir/reinstalar `rideglory-common-lib` deja a los MS con `MODULE_NOT_FOUND` o código viejo. Mitigación: checklist explícito de rebuild + reinstall ×5 MS al cerrar la fase.

## Dependencias (fases prerequisito y por que)

Ninguna (`dependsOn: []`). Esta fase es fundacional: la Fase 2 (Sentry backend con traza distribuida) reusa el envelope `_meta` y el CLS; la Fase 3 (Flutter Sentry) consume el header `x-trace-id` y el `sentry-trace` que el gateway continúa. Debe ir primero.

## Ejecucion recomendada (nivel rg-exec: full)

Cross-cutting sobre los 6 servicios, redacción PII central (Authorization, ID token, email, teléfono, SOAT, placa, VIN), nueva superficie compartida en `rideglory-common-lib` (serializer/deserializer/cls) y alto blast radius si el envelope `_meta` se diseña mal. Aunque el serializer custom evita tocar `@rideglory/contracts` y los message patterns, es infraestructura fundacional difícil de revertir y prerrequisito duro de las Fases 2 y 3. Justifica QA adversarial (intentar filtrar PII, envelopes malformados, request sin/ con `x-request-id`) y 3 rondas de auditoría Opus antes de aprobar.
