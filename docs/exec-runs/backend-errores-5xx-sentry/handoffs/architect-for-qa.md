> Slim handoff — lee esto antes de docs/exec-runs/backend-errores-5xx-sentry/handoffs/architect.md

# Architect → QA: backend-errores-5xx-sentry

## Alcance QA

Esta fase es **100% backend**. No hay tests Flutter ni `dart analyze`. Los tests son Jest (NestJS/TypeScript).

## Comandos de test

```bash
# common-lib — unitarios + specs de filtros + sentry
cd rideglory-api/rideglory-common-lib && npm test

# api-gateway — specs de filtros + instrument
cd rideglory-api/api-gateway && npm test

# Smoke test de arranque (todos los servicios sin SENTRY_DSN)
# Verificar que todos arrancan y el log de "is running on port" aparece
```

## Criterios de aceptación — traceabilidad

| CA # | Verificación | Test / Mecanismo |
|------|-------------|-----------------|
| CA-1 | 5xx en gateway → evento Sentry con `tag service: api-gateway` y `traceId` | `rpc-custom-exception.filter.spec.ts`: mock `Sentry.captureException`, assert `tags.service === 'api-gateway'` y `extra.traceId` presente |
| CA-2 | 5xx en MS → evento Sentry con tag `service` correcto y `traceId` propagado | `rpc-all-exceptions.filter.spec.ts`: mock `captureException`, assert tags y traceId |
| CA-3 | Request gateway→MS falla 5xx → mismo `traceId` en gateway y MS | Integration test o revisión manual: `traceId` del CLS en gateway == `traceId` recibido por MS via `_meta` |
| CA-4 | Error 4xx → NO genera error event; SÍ genera structured log | Spec: `captureException` NOT called; `Sentry.logger.warn` called con status/traceId |
| CA-5 | Sin `NODE_ENV=production` ni `SENTRY_DEV_VERIFY` → ningún evento enviado | `instrument.spec.ts`: spy `Sentry.init`, assert NOT called |
| CA-6 | `import './instrument'` es primera línea de los 6 `main.ts` | Code review / lint check: grep `^import './instrument'` en línea 1 de cada `main.ts` |
| CA-7 | Los 6 `config/envs.ts` aceptan `SENTRY_DSN` vacío sin error de joi | Smoke test: arranque sin var → no lanza `ENV config validation error` |
| CA-8 | Ningún evento Sentry contiene PII de la denylist | `pii-filter.spec.ts`: para cada campo de `PII_SENSITIVE_FIELDS`, construir evento con ese campo y assert que `beforeSend` lo redacta |
| CA-9 | Abstracción en common-lib; 6 servicios compilan y arrancan tras rebuild | `npm run build` en common-lib sin errores; arranque de cada MS sin `MODULE_NOT_FOUND` |
| CA-10 | Diff vacío en `@rideglory/contracts` y message patterns | `git diff HEAD -- rideglory-contracts/` debe ser vacío |
| CA-11 | `captureException` para ≥500, NO para 400/404; `Sentry.logger.warn` para 400/404, NO `captureException` | Specs de filtros con mocks |
| CA-12 | Structured logs 4xx tampoco contienen PII | `pii-filter.spec.ts`: `beforeSendLog` redacta campos de denylist |

## Verificaciones manuales recomendadas

1. Arrancar todos los servicios localmente con `SENTRY_DEV_VERIFY=true` y `SENTRY_DSN` de test → provocar un 500 y verificar que llega a Sentry con el tag correcto.
2. Verificar que un 404 NO genera issue en Sentry (solo log).
3. Verificar que el shape de respuesta HTTP del gateway hacia Flutter no cambió: `{ statusCode, message }` + header `x-trace-id`.

## Regresiones críticas a vigilar

- Shape de respuesta HTTP del gateway: `{ statusCode, message, traceId? }` — ningún campo nuevo ni eliminado
- Flujo de control de los filtros: `super.catch()` y `response.status().json()` siguen ejecutándose normalmente
- Los 6 servicios arrancan sin `SENTRY_DSN` (dev local no se rompe)
- `@rideglory/contracts` diff vacío

> Full detail: docs/exec-runs/backend-errores-5xx-sentry/handoffs/architect.md
