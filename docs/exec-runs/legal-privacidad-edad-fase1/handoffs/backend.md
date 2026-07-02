# Backend → QA / Frontend

**Fecha:** 2026-07-01T01:50:59Z
**Repo:** `rideglory-api` en `/Users/cami/Developer/Personal/rideglory-api` (super-repo, submódulos independientes). Working tree queda SUCIO a propósito (no se commiteó nada).

## Baseline

El working tree de `rideglory-api` **ya estaba sucio y con tests rojos antes de empezar** esta fase, por trabajo en curso de otras sesiones/fases sobre el mismo repo compartido (no relacionado con este alcance):

- `events-ms`: 3 tests rojos pre-existentes en `src/events/events.service.spec.ts` (TC-6/7/8, sobre `findUpcoming` — el archivo `events.service.ts` ya estaba modificado en el working tree con lógica nueva de `IN_PROGRESS`/`notIn` que el spec viejo no cubre). No toqué ese archivo ni ese spec.
- `api-gateway`: 8 tests rojos pre-existentes en `src/places/places.service.iter3.spec.ts` (geocoding), más working tree sucio en `src/home/home.controller.ts` y `src/tracking/tracking-http.controller.ts` (ajenos a esta fase).
- `users-ms`: `npm test` fallaba con "No tests found" (no había specs `.spec.ts` en el repo).
- `rideglory-contracts`: `npm run build` pasaba limpio (baseline verde).

Dado que ninguno de esos rojos pre-existentes toca los archivos de mi change map, y detenerme habría bloqueado toda la fase por un problema ajeno, seguí adelante, dejé esos rojos intactos (mismo conteo antes/después) y agregué tests nuevos que sí verifican mi código. Ver `## Resultado final` para el detalle exacto.

## Archivos cambiados

**`rideglory-contracts`**
- `src/events/dto/create-registration.dto.ts` — 4 campos opcionales: `shareMedicalInfo`, `allowOrganizerContact`, `riskAcceptedAt`, `riskAcceptanceVersion`.
- `src/events/dto/event-registration.dto.ts` — mismos 4 campos como respuesta no-opcional (`riskAcceptedAt`/`riskAcceptanceVersion` nullable).
- `src/events/dto/create-event.dto.ts` — `organizerAcceptedResponsibilityAt?: Date`. `UpdateEventDto` (extends `PartialType(CreateEventDto)`) lo hereda sin cambios.
- `src/users/dto/medical-consent.dto.ts` (nuevo) — `MedicalConsentDto`, `MedicalConsentResponseDto`, `NOT_SHARED_SENTINEL = '__NOT_SHARED__'`.
- `src/users/dto/index.ts` — export del nuevo archivo.

**`events-ms`**
- `prisma/schema.prisma` — 4 campos nuevos en `EventRegistration` (`shareMedicalInfo`/`allowOrganizerContact` boolean default false, `riskAcceptedAt`/`riskAcceptanceVersion` nullable) + `organizerAcceptedResponsibilityAt DateTime?` en `Event` (no se tocó `sosTriggeredAt`).
- `prisma/migrations/20260701014208_add_medical_consent_risk_fields/migration.sql` (nueva) — DDL additivo, aplicado a la DB local de dev (`events` en `localhost:5432`).
- `src/registrations/registrations.service.ts::create()` — se agregaron explícitamente los 4 campos nuevos al objeto `registrationData` (el hallazgo crítico del architect: este objeto se construye campo-por-campo, sin spread; sin este cambio los campos pasaban la validación del DTO pero nunca se persistían).
- `src/registrations/registrations.service.spec.ts` (nuevo) — cubre exactamente ese guardrail.

**`users-ms`**
- `prisma/schema.prisma` — `medicalConsentAcceptedAt DateTime?` en `User`.
- `prisma/migrations/20260701014335_add_medical_consent_accepted_at/` (nueva) — aplicada a la DB local de dev (`users` en `localhost:5433`).
- `src/users/users.service.ts` — nuevo método `acceptMedicalConsent(email, consentVersion)`: reusa `findByEmail` (lanza `RpcException NOT_FOUND` si no existe), setea `medicalConsentAcceptedAt = new Date()`, loguea `consentVersion` para auditoría (no hay columna de versión en el schema), retorna `{ medicalConsentAcceptedAt }`.
- `src/users/users.controller.ts` — `@MessagePattern('acceptMedicalConsent')`.
- `src/users/users.service.spec.ts` (nuevo).

**`api-gateway`**
- `src/users/users.controller.ts` — `POST /users/me/medical-consent`, mismo patrón de auth que `findMe` (401 si no hay email en el JWT; sin `@Public()`).
- `src/users/users.controller.spec.ts` (nuevo).

## Migraciones (nota sobre el flujo real)

`prisma migrate dev --create-only` en `events-ms` reportó **drift pre-existente** (una migración anterior, `20260611000000_remove_event_city`, fue modificada después de aplicarse — no relacionado con esta fase) y pedía `prisma migrate reset` (borrar toda la DB local). Para no perder datos de dev de otras fases en curso, en vez de resetear:
1. Escribí manualmente `migration.sql` (DDL additivo, verificado contra `analysis/MIGRATION_PLAN.md`).
2. Apliqué el DDL directo con `prisma db execute --file`.
3. Until logía el historial con `prisma migrate resolve --applied <nombre>`.
4. `prisma migrate status` confirma "Database schema is up to date" y `prisma generate` regeneró el client.

En `users-ms` no hubo drift; se usó el flujo estándar `prisma migrate dev`.

Ninguna migración se aplicó contra un entorno que no sea la DB local de desarrollo (`localhost:5432`/`localhost:5433`, contenedores Docker `events-db`/`users-db`).

## Pruebas nuevas

- `events-ms/src/registrations/registrations.service.spec.ts` — 2 tests: (1) los 4 campos nuevos se persisten en `eventRegistration.upsert()` (`create` y `update`) cuando vienen en el payload; (2) cuando se omiten, quedan en `false`/`false`/`null`/`null`. Mockea Prisma y `vehiclesService`/`usersService` (mismo patrón que `events.service.spec.ts`).
- `users-ms/src/users/users.service.spec.ts` — 2 tests: `acceptMedicalConsent` persiste `medicalConsentAcceptedAt` y retorna el valor; lanza `RpcException` si el usuario no existe.
- `api-gateway/src/users/users.controller.spec.ts` — 2 tests: el endpoint reenvía `email` del request autenticado + `consentVersion` del body al microservicio; lanza `UnauthorizedException` si no hay email en el JWT. (Tuvo que mockear como módulos virtuales `auth/decorators/public.decorator` y `config` porque `users.controller.ts` los importa con paths no-relativos que `tsc` resuelve vía `tsconfig.paths` pero Jest no — limitación pre-existente del repo, no específica de este cambio; no hay otros specs de controllers en `api-gateway/src/users`.)

## Resultado final

Conteos "antes" vs "después" por repo (mismos rojos pre-existentes, +4 tests nuevos verdes):

| Repo | Antes | Después |
|---|---|---|
| `rideglory-contracts` (`npm run build`) | exit 0 | exit 0 |
| `events-ms` (`npx jest`) | 3 failed, 21 passed (24 total) | 3 failed, 23 passed (26 total) — mismos 3 rojos pre-existentes en `events.service.spec.ts`, +2 tests nuevos verdes |
| `users-ms` (`npx jest`) | "No tests found" (exit 1) | 1 suite passed, 2 passed (2 total) |
| `api-gateway` (`npx jest`) | 8 failed, 101 passed (109 total) | 8 failed, 103 passed (111 total) — mismos 8 rojos pre-existentes en `places.service.iter3.spec.ts`, +2 tests nuevos verdes |

- `npx tsc --noEmit` sin errores en `events-ms`, `users-ms`, `api-gateway`.
- `npm run build` (nest build) sin errores en `events-ms`, `users-ms`, `api-gateway`.
- `eslint` sin errores nuevos: todos los errores de lint reportados en los archivos tocados son pre-existentes (verificado línea por línea contra `git diff`, no están en mis diffs); los archivos nuevos que escribí quedaron sin errores de lint.
- `prisma migrate status` → "Database schema is up to date" en `events-ms` y `users-ms`.

**status: pass**

## Verificación manual

- No se levantaron los 3 microservicios con `pnpm run start:dev` en primer plano porque ya había instancias corriendo en los puertos 3000-3004 (proceso de desarrollo activo del usuario, con código previo a mis cambios) — reiniciarlas habría interrumpido esa sesión. En su lugar:
  - Arranqué `users-ms` compilado (`node dist/src/main.js`) de forma aislada por unos segundos: los módulos cargaron sin `MODULE_NOT_FOUND` (falló solo por `EADDRINUSE` porque el puerto 3003 ya estaba tomado por la instancia existente, lo cual confirma que el build es arrancable).
  - Confirmé `nest build` limpio en los 3 servicios (proxy fuerte de "no MODULE_NOT_FOUND", ya que `nest build` resuelve todos los imports incluyendo `@rideglory/contracts`).
  - No se hizo smoke HTTP real de `POST /events/:id/registrations` ni `POST /users/me/medical-consent` contra un servidor corriendo con el código nuevo, por la razón anterior. La persistencia del criterio #5/#6 (campos nuevos no se pierden) está cubierta por el test unitario de `registrations.service.spec.ts`, que ejercita el método real `create()` con Prisma mockeado y verifica el payload exacto que se envía a `upsert()`.
- Recomendación para QA: si se necesita un smoke HTTP end-to-end, reiniciar `events-ms`/`users-ms`/`api-gateway` (`pnpm run start:dev` en cada uno) tomará el código nuevo automáticamente (ya se corrió `pnpm install` en los 3 para tomar `@rideglory/contracts` actualizado).

## Notas Frontend/QA

- `NOT_SHARED_SENTINEL = '__NOT_SHARED__'` está exportado desde `@rideglory/contracts` (`src/users/dto/medical-consent.dto.ts` → `src/users/dto/index.ts`). Fase 2 lo usará para la ofuscación condicional.
- `riskAcceptedAt` es `@IsOptional()` en `CreateRegistrationDto` a propósito — la validación de negocio `422 RISK_NOT_ACCEPTED` es de Fase 2, no de esta fase.
- `EventRegistrationDto` de respuesta ahora tiene 4 campos no-opcionales nuevos (`shareMedicalInfo`, `allowOrganizerContact`, `riskAcceptedAt`, `riskAcceptanceVersion`). Para inscripciones creadas antes de esta migración: `shareMedicalInfo`/`allowOrganizerContact` = `false`, `riskAcceptedAt`/`riskAcceptanceVersion` = `null`.
- `GET /users/me` (`findByEmail`) ya retorna `medicalConsentAcceptedAt` sin cambios de código — es un campo más del objeto Prisma completo, puede ser `null` para usuarios existentes.
- `POST /users/me/medical-consent` requiere auth (mismo guard global que el resto de `/users/*`); body: `{ consentVersion: string }`; respuesta: `{ medicalConsentAcceptedAt: Date }`.
- Working tree de `rideglory-api` tiene además cambios sin commitear de otras fases/sesiones no relacionadas con este PRD: `events-ms/src/events/events.service.ts`, `rideglory-contracts/src/events/dto/event-filter.dto.ts`, `api-gateway/src/home/home.controller.ts`, `api-gateway/src/tracking/tracking-http.controller.ts`. No los toqué ni los reviso en este handoff — quedan para quien esté ejecutando esa otra fase.
