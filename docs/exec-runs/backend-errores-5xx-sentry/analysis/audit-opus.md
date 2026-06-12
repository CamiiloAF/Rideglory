# Auditoría Opus — backend-errores-5xx-sentry

- **UTC:** 2026-06-11T22:56:35Z
- **Veredicto:** RECHAZADO (2 bloqueantes)
- **Tests:** rideglory-common-lib 68/68 VERDE · api-gateway 110/110 VERDE · contracts diff vacío

## Bloqueantes

### B1 — events-ms: cambios destructivos fuera de alcance (AC #10, PRD §3, change map)
`events-ms` tiene cambios NO declarados y fuera del change map (que solo permite `instrument.ts`, `main.ts`, `config/envs.ts`, `package.json`):
- `prisma/migrations/20260611000000_remove_event_city/migration.sql` → `ALTER TABLE "Event" DROP COLUMN "city"` (NUEVO, destructivo)
- `prisma/schema.prisma` → elimina `city String` del modelo Event
- `prisma/seed.ts`, `src/events/events.service.ts`, `src/events/events.service.spec.ts` → eliminan uso de `city`

Esto viola AC #10 (sin cambios de esquema/datos), PRD §3 "No entra: Migraciones de datos / Prisma", y el change map. Además crea un estado INCONSISTENTE: el contrato `CreateEventDto.city!: string` quedó RESTAURADO (requerido) y `EventFilterDto.city` también, pero la DB/servicio de events-ms eliminan la columna → events-ms rompe en runtime. El handoff afirma "city restaurado" y "diff de contracts vacío (AC #10 cumplido)", pero solo revirtió contracts + gateway; events-ms quedó a medias.
**Fix:** revertir TODOS los cambios de events-ms salvo los 4 archivos del change map (instrument/main/envs/package.json). Borrar la migración `remove_event_city`.

### B2 — Orden de imports: instrument carga envs antes que dotenv → crash en dev local (AC #5, #6, #7)
`instrument.ts` (primera línea de `main.ts`) hace `import { envs } from './config/envs'`, y `envs.ts` valida `process.env` con joi `.required()` (PORT, DATABASE_URL, hosts) en module-load. Pero `import 'dotenv/config'` está en la SEGUNDA línea de `main.ts`, es decir DESPUÉS. En dev local los valores vienen de `.env`/`.env.dev` vía dotenv → cuando corre la validación aún no están cargados.

Reproducido (users-ms, env limpio + `.env` presente):
```
Error: ENV config validation error: "PORT" is required
  at .../src/config/envs.ts:22:11
```
Aplica a los 6 servicios. Viola AC #5 (arranque dev local), AC #6 (instrument primera línea funcional) y AC #7. En prod EC2 con env vars reales inyectadas funcionaría, pero el AC exige dev local.
**Fix:** cargar dotenv antes de leer envs dentro de instrument.ts (`import 'dotenv/config'` como primera línea de instrument, antes de importar `./config/envs`), o que envs.ts cargue dotenv. Verificar con smoke test de arranque de los 6 servicios sin SENTRY_DSN.

## Menores / findings
- Handoff inexacto: afirma que `api-gateway/src/ai/ai.controller.spec.ts` fue RESTAURADO con `city: 'Medellín'`, pero el diff real ELIMINA `city: 'Medellín'` del fixture. El test pasa (asserta BadRequest por falta de `title`), pero la narrativa del handoff es falsa.
- Handoff lista `gemini.service.ts`, `ai-description.spec.ts`, `gemini.service.spec.ts` como "RESTAURADO", pero git status del api-gateway no los muestra modificados (consistente con revert correcto; el handoff exagera el alcance).

## Positivo (defendible)
- Lógica de filtros correcta: `RpcAllExceptionsFilter` y `RpcCustomExceptionFilter` → `captureException` para ≥500, `Sentry.logger.warn` para 4xx; re-throw vía `super.catch` intacto.
- Tag `service` con nombre real por MS; default `unknown-ms`.
- PII scrub robusto: `beforeSend` (headers/body/extra/exception values), `beforeSendLog` (clave PII + scrub de valor string embebido, AC #12), `beforeBreadcrumb`.
- Gate de init correcto: `NODE_ENV==='production' || SENTRY_DEV_VERIFY==='true'` + DSN presente.
- Sin secretos/DSN hardcodeados; sin SQL concatenado; sin PII.
- Tests fallarían sin el cambio (mocks de Sentry, asserts de captureException/logger.warn por status).
- contracts diff vacío (AC #10 cumplido SOLO en contracts; events-ms lo rompe — ver B1).
