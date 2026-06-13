# PRD Normalizado — Backend: errores 5xx en Sentry con traza distribuida

- **Generado (UTC):** 2026-06-11T22:19:49Z
- **Slug:** `backend-errores-5xx-sentry`
- **Fuente:** `docs/plans/observability-sentry/phases/phase-02-backend-errores-5xx-en-sentry-con-traza-distribu.md`
- **Depende de:** Fase 1 (traceId distribuido, envelope `_meta`, denylist PII en `rideglory-common-lib`)

---

## 1 Objetivo

Instrumentar los 6 servicios del backend (`api-gateway`, `users-ms`, `events-ms`, `vehicles-ms`, `maintenances-ms`, `notifications-ms`) para que los errores **5xx** aparezcan en Sentry como **error events** (con alerta), correlacionados por `traceId` y por el tag `service`. Los **4xx** se envían a Sentry como **structured logs** (`Sentry.logger.warn`) sin generar *issue* ni alerta, preservando la cuota de errores (5k/mes). La instrumentación se activa solo en producción (`NODE_ENV === 'production'`), con una palanca temporal `SENTRY_DEV_VERIFY=true` para verificación durante el rollout. Nunca filtra PII ni secretos al exterior.

---

## 2 Por qué

El equipo no tiene visibilidad sobre los crashes backend en producción. Sin correlación por `traceId` es imposible rastrear un error HTTP hasta el microservicio origen. La separación 5xx (error event) vs 4xx (structured log) protege la cuota free de Sentry (5k errores/mes) y evita alertas ruidosas por errores de negocio esperados. La abstracción en `rideglory-common-lib` previene la divergencia del patrón a través de los 6 servicios, que sería costosa de mantener y auditar.

---

## 3 Alcance

### Entra
- `instrument.ts` por servicio (×6) con `initSentry(...)`, importado como primera línea de cada `main.ts`.
- Helper `initSentry` y wrapper `SentryModule` en `rideglory-common-lib`, reutilizados ×6.
- Extensión de `RpcCustomExceptionFilter` (gateway) y `RpcAllExceptionsFilter` (common-lib): `status >= 500` → `captureException`; 4xx → `Sentry.logger.warn` (structured log).
- `enableLogs: true` en `Sentry.init` para habilitar structured logs de 4xx.
- Propagación de `sentry-trace`/`baggage` en el envelope `_meta` (canal de Fase 1) para cerrar el trace HTTP↔TCP.
- Tag `service` en todos los eventos/logs (`api-gateway`, `users-ms`, etc.); un solo proyecto Sentry.
- `NODE_ENV` y `SENTRY_DSN` (opcional, joi) en los 6 `config/envs.ts`.
- `beforeSend`/`beforeSendLog`/`beforeBreadcrumb` con denylist PII centralizada (Fase 1).
- `tracesSampleRate` configurable por env.
- Palanca temporal `SENTRY_DEV_VERIFY=true` (reversible al cerrar las fases Sentry).
- Rebuild + reinstalación disciplinada de `rideglory-common-lib` en los 6 servicios.

### No entra
- Cambios en `@rideglory/contracts`, DTOs o los ~56 message patterns.
- Migraciones de datos / Prisma.
- Sentry en Flutter (Fase 3).
- Tracing del canal WebSocket `/tracking/ws` (solo documentar limitación).
- Creación de filtros de excepción nuevos (se extienden los existentes).
- Dashboards / alertas en la consola Sentry.

---

## 4 Áreas afectadas

| Área | Detalle |
|------|---------|
| `rideglory-api/rideglory-common-lib` | Nueva carpeta `src/sentry/` (`init-sentry.ts`, `sentry.module.ts`); extensión de `rpc-all-exceptions.filter.ts`; barrel `index.ts` actualizado |
| `rideglory-api/api-gateway` | `src/instrument.ts` (nuevo), `src/main.ts` (primera línea), `src/app.module.ts` (SentryModule), `src/common/exceptions/rpc-custom-exception.filter.ts`, `src/config/envs.ts` |
| `rideglory-api/{users,events,vehicles,maintenances,notifications}-ms` | `src/instrument.ts` (nuevo ×5), `src/main.ts` (primera línea ×5), `src/app.module.ts` (×5), `src/config/envs.ts` (×5) |
| `rideglory-api/*/package.json` | Dependencia `@sentry/nestjs` / `@sentry/node` donde corresponda |
| Tests backend | Nuevas suites unitarias para filtros, `initSentry` gating, `beforeSend` PII y arranque dev |

---

## 5 Criterios de aceptación

1. Con `NODE_ENV=production` y `SENTRY_DSN` válido, un error `>= 500` en el gateway produce **un** evento en Sentry con `tag service: api-gateway` y el `traceId` del request.
2. Con `NODE_ENV=production` y `SENTRY_DSN` válido, un error no controlado `>= 500` en cualquier MS produce **un** evento en Sentry con el tag `service` correcto y el `traceId` propagado por `_meta`.
3. Un request que atraviesa gateway→MS y falla con 5xx genera eventos cuyo `traceId` es **el mismo** en gateway y MS (trace HTTP↔TCP cerrado).
4. Un error de negocio 4xx (p.ej. `BadRequest`, `NotFound`) **no** genera *error event* en Sentry, pero **sí** produce un structured log (`Sentry.logger.warn`) con `traceId`/`service`/status, y se loguea por pino.
5. Con `NODE_ENV !== 'production'` o `SENTRY_DSN` vacío, **ningún** servicio envía eventos a Sentry y los 6 servicios arrancan correctamente en dev local.
6. `import './instrument';` es la **primera línea** de los 6 `main.ts`; un error de prueba confirma que la instrumentación NestJS está activa por servicio.
7. Los 6 `config/envs.ts` validan `NODE_ENV` y `SENTRY_DSN` (opcional) sin romper el arranque cuando faltan en dev.
8. Ningún evento Sentry (campos `request`, `extra`, `contexts`, `breadcrumbs`) contiene PII de la denylist (Authorization, ID token, password, email, teléfono, SOAT, placa, VIN), verificado por test sobre `beforeSend`/`beforeBreadcrumb`.
9. La tríada serializer/deserializer/cls + el bootstrap de Sentry viven en `rideglory-common-lib` y se registran ×6 sin copy-paste divergente; tras `npm run build` + reinstalación los 6 servicios compilan y arrancan.
10. No hay cambios en `@rideglory/contracts`, en los message patterns ni en el esquema de datos (diff vacío en esas superficies).
11. Tests unitarios de cada filtro verifican que `captureException` se llama para `>= 500` y **no** para 400/404; para 400/404 se verifica que se llama `Sentry.logger.warn` y **no** `captureException`.
12. Los atributos de los structured logs de 4xx (`Sentry.logger.warn`) tampoco contienen PII de la denylist, verificado por `beforeSendLog`.

---

## 6 Guardrails de regresión

- **Contrato HTTP hacia Flutter intacto:** la respuesta de error del gateway mantiene `{ statusCode, message }` con el header `x-trace-id` (Fase 1). Ningún campo nuevo ni rotura de shape.
- **Sin cambios en `@rideglory/contracts`:** diff vacío en DTOs y message patterns; la regresión se detecta en CI con `tsc --noEmit`.
- **Filtros de excepción mantienen su comportamiento de re-lanzado:** `RpcException` con `{ status, message }` sigue propagándose normalmente al gateway; la extensión es aditiva (Sentry) sin alterar el flujo de control existente.
- **Dev local no se rompe sin DSN:** smoke test de arranque de los 6 servicios sin `SENTRY_DSN` antes de considerar la fase completa.
- **`beforeSend` PII como gate de seguridad:** test que falla si cualquier campo de la denylist llega sin redactar; debe correr en CI antes de habilitar el DSN de producción.
- **Rebuild de common-lib disciplinado:** `npm run build` en la lib + reinstalación en los 6 MS; verificar que no queda ningún módulo con la versión anterior (`MODULE_NOT_FOUND` en arranque es señal de gotcha no resuelto).
- **Palanca `SENTRY_DEV_VERIFY` reversible:** al cerrar las fases Sentry se elimina la rama condicional y se deja solo `NODE_ENV === 'production' && !!dsn`; el PR final no debe incluir `SENTRY_DEV_VERIFY`.

---

## 7 Constraints heredados

- **Fase 1 prerequisito duro:** esta fase reutiliza el `traceId` distribuido por TCP (serializer/deserializer + `nestjs-cls`), el envelope `_meta` extensible y la denylist PII centralizada de Fase 1. Sin esa base no hay `traceId` compartido entre gateway y MS.
- **Un solo proyecto Sentry con tag `service`:** decisión cerrada; no crear proyectos por microservicio.
- **Cuota free Sentry:** 5k error events/mes + 5 GB structured logs/mes. Los 4xx van como logs para no consumir la cuota de errores. `tracesSampleRate` configurable por env para controlar el volumen de traces.
- **Sin PII en Sentry:** la denylist cubre Authorization, ID token, password, email, teléfono, SOAT, placa, VIN. Es un constraint de seguridad/privacidad, no negociable.
- **`instrument.ts` como primera importación:** el SDK de Sentry requiere cargarse antes de `@nestjs/core` para instrumentar correctamente; el orden en `main.ts` es crítico (R7 del plan).
- **Abstracción en common-lib obligatoria:** la divergencia ×6 del patrón es un riesgo explícito (R5); la abstracción en `rideglory-common-lib` es criterio de aceptación, no opcional.
- **Tracing WS fuera de alcance:** el canal `/tracking/ws` no se traza en esta fase; solo se documenta la limitación.
