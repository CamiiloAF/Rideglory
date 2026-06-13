# PRD Normalizado — observability-sentry-phase01

- **Generado (UTC):** 2026-06-11T19:18:31Z
- **Fuente:** docs/plans/observability-sentry/phases/phase-01-backend-traceid-distribuido-por-tcp-logs-estruct.md
- **Repo objetivo:** `rideglory-api` (backend); Flutter no cambia en esta fase.

---

## 1 Objetivo

Hacer que operación y soporte puedan seguir cualquier request por su `traceId` desde el gateway HTTP hasta cada microservicio TCP, con logs estructurados (JSON en prod, legibles en dev) y sin exponer PII ni secretos. El `traceId` se genera (o se continúa desde `x-request-id`/`sentry-trace` entrante) en el gateway, viaja por TCP en un envelope `_meta` extensible sin modificar `.send()`, DTOs ni los ~56 message patterns, y regresa al cliente por el header `x-trace-id`. Esta fase no incluye Sentry; deja lista la base de correlación que las Fases 2 y 3 consumen.

---

## 2 Por qué

Sin trazabilidad distribuida, un error intermitente que atraviesa gateway → microservicio es imposible de correlacionar en los logs. La plataforma tiene 6 servicios (gateway + 5 MS) comunicados por TCP; los logs actuales no tienen identificador común de request, están en texto plano y pueden filtrar datos sensibles. Esta fase establece la infraestructura fundacional de observabilidad de la que dependen Sentry backend (Fase 2) y Sentry Flutter (Fase 3).

---

## 3 Alcance

**Entra:**
- `nestjs-pino` (con `pino-pretty` en dev, JSON en prod) en el gateway y los 5 microservicios (`users-ms`, `events-ms`, `vehicles-ms`, `maintenances-ms`, `notifications-ms`).
- Reemplazo de `HttpLoggerMiddleware` por logging de pino + interceptor de gateway (método, ruta, status, latencia, `traceId`).
- `nestjs-cls` en el gateway: genera o continúa el `traceId` por request.
- Serializer custom del `ClientProxy` en los 9 módulos gateway que registran `ClientsModule`: inyecta `_meta` (con `traceId`) en el envelope TCP, sin tocar `.send()` ni DTOs.
- Deserializer custom + interceptor RPC en cada MS: extrae `_meta.traceId` y lo siembra en el CLS del MS para que pino lo emita línea a línea.
- Redacción PII en dos capas: `redact` nativo de pino (por path) + interceptor request/response con allowlist. Denylist centralizada con test anti-regresión.
- Header de respuesta `x-trace-id` desde el gateway; campo `traceId` en cuerpos de error (nunca como copy visible).
- Nueva superficie compartida `rideglory-common-lib/src/observability/`: serializer, deserializer, interceptor CLS, denylist PII, factory de opciones pino, exportada desde `index.ts`.

**No entra:**
- Sentry (`instrument.ts`, `SentryModule`, `@sentry/*`) → Fase 2.
- Transporte de `sentry-trace`/`baggage` en `_meta` → Fase 2 (el envelope se diseña extensible ahora).
- Cambios en Flutter (consumo de `x-trace-id`) → Fase 3.
- Tracing del canal WebSocket `/tracking/ws` → best-effort, fuera de alcance core; solo documentar la limitación.
- Modificar `@rideglory/contracts`, DTOs de payload ni firmas de message patterns.
- Variables de entorno `NODE_ENV`/`SENTRY_DSN` en joi → Fase 2.

---

## 4 Áreas afectadas

| Área | Detalle |
|---|---|
| `rideglory-common-lib` | Nueva carpeta `src/observability/` (7 archivos nuevos); modificar `src/index.ts`. |
| `api-gateway` | `main.ts`, `app.module.ts`, 9 módulos con `ClientsModule`, `rpc-custom-exception.filter.ts`; eliminar `http-logger.middleware.ts`; `package.json`. |
| `users-ms` | `main.ts`, `app.module.ts`, `package.json`. |
| `events-ms` | `main.ts`, `app.module.ts`, `package.json`. |
| `vehicles-ms` | `main.ts`, `app.module.ts`, `package.json`. |
| `maintenances-ms` | `main.ts`, `app.module.ts`, `package.json`. |
| `notifications-ms` | `main.ts`, `app.module.ts`, `package.json`. |
| Tests | Unitarios (denylist PII, serializer, deserializer) + integración (propagación e2e, redacción) + humo de arranque ×6. |
| Flutter (`lib/`) | Sin cambios en esta fase. |
| Prisma / base de datos | Sin cambios. |
| `@rideglory/contracts` | Sin cambios. |

---

## 5 Criterios de aceptación

1. Un request HTTP al gateway produce un `traceId` que aparece **idéntico** en al menos una línea de log del gateway y en al menos una línea de log del MS invocado.
2. Si el request entrante trae `x-request-id` (o `sentry-trace`), el `traceId` lo **continúa** en vez de generar uno nuevo; si no trae, genera uno nuevo.
3. La respuesta HTTP incluye el header `x-trace-id` con el mismo `traceId`; los cuerpos de error incluyen el campo `traceId`.
4. En dev los logs salen legibles (`pino-pretty`); en prod salen en JSON estructurado (una línea por evento).
5. Ningún campo de la denylist (`Authorization`, ID token, `password`, `email`, teléfono, SOAT, placa, VIN) aparece en claro en ninguna línea de log ni en el cuerpo de respuesta: queda redactado por las dos capas (pino `redact` + interceptor allowlist).
6. Los ~56 message patterns y los DTOs de `@rideglory/contracts` **no** cambian de firma; el diff no toca esos archivos.
7. El serializer/deserializer/cls-setup/denylist viven en `rideglory-common-lib/src/observability/` y se consumen desde la lib en gateway y MS (sin copias divergentes); `index.ts` exporta `./observability`.
8. `HttpLoggerMiddleware` queda eliminado y no referenciado en `app.module.ts`.
9. El interceptor de logging del gateway emite método, ruta, status, latencia y `traceId` por cada request.
10. Sin Sentry: no hay `instrument.ts`, `SentryModule` ni dependencias `@sentry/*` introducidas en esta fase.
11. Cada uno de los 6 servicios arranca correctamente con el logger de pino activo (humo de arranque sin errores de DI ni de import).

---

## 6 Guardrails de regresión

- **PII:** test unitario de denylist que falla si cualquier campo sensible queda en claro tras el helper de redacción; test que falla si se añade un campo sensible nuevo sin cubrirlo en la denylist.
- **Contracts intactos:** el diff no debe incluir cambios en ningún archivo de `@rideglory/contracts` ni en los ~56 message patterns.
- **Arranque ×6:** todos los servicios levantan sin errores; un fallo de arranque bloquea la aprobación de la fase.
- **Backwards compatibility del envelope:** envelope sin `_meta` (request de cliente externo sin header) no rompe el deserializer ni los flujos existentes.
- **Rebuild de common-lib obligatorio:** tras cualquier cambio en `rideglory-common-lib`, ejecutar `npm run build` en la lib + `npm install`/`pnpm install` en cada MS consumidor antes de correr pruebas; omitirlo produce `MODULE_NOT_FOUND` con código viejo.
- **Piloto primero:** validar un MS extremo a extremo (recomendado `users-ms`) antes de replicar el patrón en los otros 4 MS y los 9 módulos gateway.
- **Sin Sentry en esta fase:** cualquier introducción de `@sentry/*`, `SentryModule` o `instrument.ts` es un fallo de scope.

---

## 7 Constraints heredados

- **Backend repo:** todos los cambios van en `/Users/cami/Developer/Personal/rideglory-api`.
- **Flutter sin cambios:** `lib/` de Rideglory no se toca en esta fase; el consumo de `x-trace-id` queda para la Fase 3.
- **`_meta` extensible:** el envelope TCP se define como `interface TcpMeta { traceId: string; [key: string]: unknown }` para que la Fase 2 añada `sentry-trace`/`baggage` sin rehacer el serializer.
- **WebSocket best-effort:** `/tracking/ws` queda fuera del alcance core; solo documentar la limitación sin bloquear.
- **Dependencias de fase:** esta fase no tiene prerrequisitos (`dependsOn: []`) pero es prerrequisito duro de la Fase 2 (Sentry backend) y la Fase 3 (Flutter Sentry).
- **Nivel recomendado:** `full` (cross-cutting ×6 servicios, infraestructura fundacional, redacción PII crítica, alto blast radius si el envelope se diseña mal).
- **Sin commits automáticos:** el árbol de trabajo queda sucio; el humano commitea tras revisar.
