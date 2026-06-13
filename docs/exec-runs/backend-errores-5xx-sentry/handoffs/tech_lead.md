# Tech Lead Handoff — backend-errores-5xx-sentry

**Generado (UTC):** 2026-06-11T23:23:27Z
**Agente:** tech_lead (claude-sonnet-4-6) — RE-REVISIÓN
**Branch backend:** main (submodules con working tree modificado)

---

## Veredicto

**ready** — B1 y B2 resueltos en la iteración de corrección. 212 tests pasan en verde (76 common-lib + 110 api-gateway + 26 events-ms). No hay bloqueantes activos.

---

## Hallazgos

### ~~B1~~ RESUELTO — events-ms: sin migración destructiva

El working tree de events-ms no contiene la migración `remove_event_city` ni cambios a `prisma/schema.prisma`, `prisma/seed.ts` ni `events.service.ts`. El diff de `prisma/` es vacío. Los cambios en `events.service.spec.ts` son una corrección de tests que estaban desalineados con lógica ya existente en `events.service.ts` (del commit de fase 1), no una modificación de comportamiento. Los 26 tests de events-ms pasan.

**rideglory-contracts diff: vacío — AC #10 cumplido.**

### ~~B2~~ RESUELTO — instrument.ts no importa envs

Los 6 `instrument.ts` leen `process.env['SENTRY_DSN']` y `process.env['SENTRY_TRACES_SAMPLE_RATE']` directamente, sin importar `envs`. Cada archivo incluye un comentario documentando explícitamente la razón (evitar race condition con dotenv). AC #5 y AC #7 cumplidos.

---

## Seguridad

**Sin hallazgos críticos de seguridad.** Lo siguiente fue verificado:

- No hay DSN hardcodeado ni secretos en código. `SENTRY_DSN` se lee de `process.env` via joi opcional.
- No hay SQL concatenado ni inyección.
- `beforeSend`, `beforeSendLog`, `beforeBreadcrumb` implementados con denylist centralizada `PII_SENSITIVE_FIELDS`. Cubren: headers, body (objeto y string), extra, exception values y valores string embebidos en atributos de logs (AC #12).
- `captureException` solo se llama después del gate `NODE_ENV=production || SENTRY_DEV_VERIFY=true` — en dev sin DSN no se envía nada.
- Shape HTTP de respuesta intacto (`{statusCode, message, traceId?}` + header `x-trace-id`). Ningún campo nuevo ni PII expuesto al cliente Flutter.
- `RpcAllExceptionsFilter` usa duck-typing `ClsLike` (sin hard dep a `nestjs-cls`) para leer `traceId` del CLS context. El traceId se incluye en `extra` (no en tags), correcto para Sentry.

**Riesgo menor**: `beforeSend` scruba `exception.values[].value` via `scrubString` (regex `key=value`). No cubre PII embebido solo como valor en una string sin clave (e.g., `"user email is foo@bar.com"`). Aceptable para esta fase; documentar en backlog si se requiere scrub más agresivo.

---

## Arquitectura

**Decisiones correctas y alineadas con el architect handoff:**

- `initSentry` en common-lib: abstracción ×6 sin divergencia (D1 cumplido).
- Gate `NODE_ENV === 'production' || SENTRY_DEV_VERIFY === 'true'` (D4 cumplido).
- `@sentry/nestjs` en api-gateway, `@sentry/node` en los 5 MS TCP (D2 cumplido).
- Tag `service` como string literal por servicio; default `'unknown-ms'` (D8 cumplido).
- `RpcCustomExceptionFilter` en api-gateway y `RpcAllExceptionsFilter` en common-lib: extensión aditiva sin alterar re-throw (D6, D7 cumplidos).
- `enableLogs: true` en `Sentry.init` (D11 cumplido).
- `SentryModule` stub documental — no registra providers, no se importa en `AppModule`. Correcto dado que la init ocurre en `instrument.ts` antes del bootstrap (D12 cumplido).

**Punto aceptado**: `RpcAllExceptionsFilter` acepta `cls?: ClsLike` como segundo parámetro del constructor. Los 6 `main.ts` pasan solo el nombre del servicio sin `cls` — el `traceId` en los eventos de los MS será `undefined`. Esto es deuda técnica aceptada para esta fase (el traceId llega al gateway via headers). Para completar la correlación MS→Sentry se debe inyectar `ClsService` desde `AppModule` via factory provider en una fase posterior.

---

## Tests

**212 tests verificados en vivo — 0 fallos.**

| Suite | Tests | Baseline | Estado |
|-------|-------|---------|--------|
| rideglory-common-lib | 76 | 56 | VERDE (ejecutado) |
| api-gateway | 110 | 110 | VERDE (ejecutado) |
| events-ms | 26 | 26 | VERDE (ejecutado) |

Cobertura por AC:

| AC | Cubierto | Notas |
|----|---------|-------|
| AC-1 | Sí | `rpc-custom-exception.filter.spec.ts` — captureException con tag + traceId |
| AC-2 | Sí | `rpc-all-exceptions.filter.spec.ts` — it.each ×5 MS names |
| AC-3 | Parcial | Unit: mismo traceId en extra; integración real requiere prueba manual |
| AC-4 | Sí | logger.warn para 4xx con traceId/service/status; no captureException |
| AC-5 | Sí | `instrument.spec.ts` — gate dev/prod/dsn |
| AC-6 | Code review | grep confirma línea 1 en los 6 main.ts |
| AC-7 | Sí (joi optional) | **En riesgo por BUG-2** — dev local crashea antes de usar joi |
| AC-8 | Sí | `pii-filter.spec.ts` — covers all PII_SENSITIVE_FIELDS |
| AC-9 | Sí | common-lib 76 tests verdes |
| AC-10 | Sí en contracts | **Violado por events-ms** — B1 |
| AC-11 | Sí | Ambas suites de filtros |
| AC-12 | Sí | `beforeSendLog` + test de valor string embebido |

---

## Pruebas manuales

Listas para ejecutar (no hay bloqueantes previos):

1. **Smoke test dev local** (AC #5, #7): arrancar los 6 servicios sin `SENTRY_DSN`. Todos deben iniciar sin error.
2. **Gate prod** (AC #5): arrancar con `NODE_ENV=production` sin `SENTRY_DSN`. Debe arrancar normalmente, sin llamada a `Sentry.init`.
3. **5xx en gateway** (AC #1): provocar un error interno con `SENTRY_DEV_VERIFY=true` + `SENTRY_DSN` de test. Verificar en Sentry: evento con `tag service: api-gateway`, `extra.traceId`, sin PII.
4. **4xx en gateway** (AC #4): provocar un 404. Verificar: NO aparece como error event en Sentry; SÍ como structured log.
5. **Shape HTTP** (regresión): `curl` con error → `{statusCode, message}` con header `x-trace-id` intacto.
6. **PII** (AC #8): enviar payload con `email`/`password` y provocar error → verificar en Sentry: `[Filtered]`.
