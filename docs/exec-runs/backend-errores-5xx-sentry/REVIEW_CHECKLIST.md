# REVIEW CHECKLIST — backend-errores-5xx-sentry

**Generado (UTC):** 2026-06-11T23:23:27Z
**Tech Lead (re-revisión):** claude-sonnet-4-6
**Veredicto:** ready — B1 y B2 resueltos; no hay bloqueantes activos.

---

## ~~Bloqueo B1~~ — RESUELTO

Events-ms **no contiene** la migración destructiva `remove_event_city` ni cambios a `prisma/schema.prisma` o `events.service.ts` en el working tree actual. El diff de `prisma/` en events-ms es vacío. Verificado con `git diff HEAD -- prisma/` y `git status`.

El cambio que sí existe en `src/events/events.service.spec.ts` es una corrección de tests que estaban desalineados con la lógica ya existente en `events.service.ts` (commit de fase 1 anterior). No modifica comportamiento de producción y los 26 tests pasan.

---

## ~~Bloqueo B2~~ — RESUELTO

Todos los `instrument.ts` (×6) leen `process.env['SENTRY_DSN']` directamente sin importar `envs`. El comment en cada archivo documenta explícitamente la razón. La race condition dotenv/joi está eliminada.

---

Los siguientes archivos de events-ms NO pertenecen a esta fase (PRD §3: sin migraciones Prisma):

```bash
cd rideglory-api/events-ms

# Revertir archivos modificados fuera del change map
git checkout -- prisma/schema.prisma
git checkout -- prisma/seed.ts
git checkout -- src/events/events.service.ts
git checkout -- src/events/events.service.spec.ts

# Borrar la migración destructiva (nunca commitear)
rm -rf prisma/migrations/20260611000000_remove_event_city/
```

Verificar tras el revert:
- `git diff prisma/schema.prisma` → vacío
- `git diff src/events/events.service.ts` → vacío
- `ls prisma/migrations/` → sin `20260611000000_remove_event_city`
- `grep 'city' prisma/schema.prisma` → debe encontrar `city String` en modelo Event

---

## Bloqueo B2 — Corregir instrument.ts en los 6 servicios (dotenv race condition)

`instrument.ts` importa `envs` que ejecuta joi validation antes de que `dotenv/config` se cargue.
Fix: leer las 3 vars Sentry directamente de `process.env` sin pasar por `envs`.

Patrón correcto para cada `instrument.ts` (reemplazar el contenido actual):

```typescript
// Must be the FIRST import in main.ts — before dotenv/config and @nestjs/core
// so that Sentry can instrument NestJS correctly.
import { initSentry } from '@rideglory/common-lib';

// Read Sentry env vars directly — do NOT import `envs` here because
// envs.ts runs joi validation at module-load time, and dotenv/config
// has not been executed yet (it runs on line 2 of main.ts).
const sentryDsn = process.env['SENTRY_DSN'];
const sentryRate = process.env['SENTRY_TRACES_SAMPLE_RATE'];

initSentry('<service-name>', sentryDsn, {
  tracesSampleRate: sentryRate ? Number(sentryRate) : undefined,
});
```

Servicios a corregir (sustituir `<service-name>` por el nombre real):
- `rideglory-api/api-gateway/src/instrument.ts` → `'api-gateway'`
- `rideglory-api/users-ms/src/instrument.ts` → `'users-ms'`
- `rideglory-api/events-ms/src/instrument.ts` → `'events-ms'`
- `rideglory-api/vehicles-ms/src/instrument.ts` → `'vehicles-ms'`
- `rideglory-api/maintenances-ms/src/instrument.ts` → `'maintenances-ms'`
- `rideglory-api/notifications-ms/src/instrument.ts` → `'notifications-ms'`

Smoke test tras el fix:
```bash
# Sin SENTRY_DSN (solo vars requeridas en .env)
cd rideglory-api/api-gateway && npm run start:dev
# Esperado: arranque exitoso sin error de joi

cd rideglory-api/users-ms && npm run start:dev
# ídem para cada MS
```

---

## Menor W1 — (ya no aplica)

El fixture `city: 'Medellín'` en `ai.controller.spec.ts` fue verificado: el diff de api-gateway solo muestra un cambio menor en ese archivo (restauración de `city`). Los 110 tests de api-gateway pasan.

---

## Verificación de contratos (confirmación)

```bash
cd rideglory-api/rideglory-contracts && git diff
# Esperado: vacío (AC #10)
```

---

## Smoke test de arranque final (AC #5, #7)

Tras resolver B1 y B2, arrancar los 6 servicios sin `SENTRY_DSN`:

```bash
# Cada MS en su carpeta con solo las vars del .env existente (sin SENTRY_DSN)
npm run start:dev
# Todos deben arrancar sin error
```

---

## Prueba manual end-to-end (AC #1, #2, #3, #4) — post-deploy staging

Con `SENTRY_DEV_VERIFY=true` y `SENTRY_DSN` de proyecto Sentry test:

1. **5xx en gateway**: provocar un error interno en el gateway → verificar en Sentry: evento con `tag service: api-gateway`, `extra.traceId` poblado, sin PII.
2. **5xx en MS**: provocar un error interno en users-ms → verificar: evento con `tag service: users-ms`, mismo `traceId`.
3. **4xx en gateway**: provocar un 404 o BadRequest → verificar en Sentry: NO aparece como error event; SÍ aparece como structured log `Sentry.logger.warn`.
4. **Shape HTTP**: `curl` al gateway con error → respuesta `{statusCode, message, traceId?}` con header `x-trace-id` intacto.
5. **PII**: provocar error con payload que contenga `email`/`password` → verificar en Sentry: campos aparecen como `[Filtered]`.
