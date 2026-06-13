# Auditoría — backend-errores-5xx-sentry

- **Auditor:** Opus
- **Fecha (UTC):** 2026-06-11T22:45:58Z
- **Veredicto:** RECHAZADO (score 58)

## Resumen

La instrumentación Sentry está bien diseñada en common-lib y gateway: gating
(`NODE_ENV==='production' || SENTRY_DEV_VERIFY`), `enableLogs`, denylist PII en
`beforeSend`/`beforeSendLog`/`beforeBreadcrumb`, separación 5xx→captureException /
4xx→logger.warn, `x-trace-id` y shape `{statusCode,message,traceId?}` intactos.
Build y resolución en runtime OK (deps hoisted al root + common-lib reconstruido;
NO hay MODULE_NOT_FOUND). Tests verdes (common-lib 21, gateway 12 de la superficie nueva).

Sin embargo hay 2 fallos bloqueantes en aceptación + 1 gap PII.

## Bloqueantes

### B1 — Tag `service` = `unknown-ms` en los 5 microservicios (AC #2, #9)
Los 6 `instrument.ts` pasan el nombre correcto a `initSentry(...)` (initialScope),
PERO el filtro se registra como `new RpcAllExceptionsFilter()` SIN argumento en los 5 MS
(`users/events/vehicles/maintenances/notifications-ms/src/main.ts`). El constructor nuevo
acepta `service?: string`; al no recibirlo cae en `'unknown-ms'`, y como el tag pasado en
`captureException(..., {tags:{service}})` SOBRESCRIBE el tag de `initialScope`, todos los
eventos 5xx y logs 4xx de los MS quedan etiquetados `unknown-ms`. Rompe la correlación por
`service`, núcleo del PRD.

### B2 — Cambios fuera del change map / contracts con diff no vacío (AC #10, change map)
El working tree incluye un cambio "eliminar `city`" no relacionado con Sentry:
- `rideglory-contracts/src/events/dto/{create-event,event-filter}.dto.ts`, `ai/dto/ai-description-event-context.dto.ts`
- `api-gateway/src/ai/{gemini.service,*.spec}.ts`
El PRD exige diff VACÍO en `@rideglory/contracts` (guardrail + AC #10) y "solo archivos del
change map". Estos archivos contaminan la entrega que el humano commiteará.

## Menor

### M1 — Logs 4xx: el VALOR del atributo `message` no se redacta (AC #12)
`beforeSendLog` redacta por KEY del denylist; el contenido dinámico va al atributo `message`
(key no-PII), así que un mensaje 4xx como "placa ABC123 no encontrada" llegaría sin redactar.
El test solo cubre redacción por key. Aplicar `scrubString` al valor de `message`/atributos string.

## Cambios requeridos
1. Pasar el nombre a cada filtro: `new RpcAllExceptionsFilter('users-ms')` (y events/vehicles/
   maintenances/notifications) en cada `main.ts`. Añadir test que verifique el tag real.
2. Revertir/separar los cambios "city" en `rideglory-contracts` y `api-gateway/src/ai/*`
   para dejar la superficie de contracts con diff vacío.
3. (Menor) Aplicar `scrubString` a valores string en `beforeSendLog` y test de PII por valor en log 4xx.
