# Architect handoff — legal-privacidad-edad-fase1

**Date:** 2026-07-01T01:34:57Z
**Status:** done
**Repos:** `rideglory-api` at `/Users/cami/Developer/Personal/rideglory-api` (super-repo, submodules: `events-ms`, `users-ms`, `api-gateway`, `rideglory-contracts`). This worktree (`lib/`) is **not touched** — 100% backend phase.

## Decisiones

1. **`bloodType: BloodType | string` NO se toca en esta fase.** Verifiqué `event-registration.dto.ts`: hoy es `bloodType!: BloodType` (enum estricto), no `BloodType | string`. El guardrail #6 del PRD normalizado es una advertencia preventiva heredada del plan padre, no una tarea de esta fase — no aparece en §3 "Entra". No se cambia el tipo aquí; queda documentado como riesgo latente para si una fase futura lo introduce.
2. **`NOT_SHARED_SENTINEL` vive en `rideglory-contracts/src/users/dto/medical-consent.dto.ts`** (mismo archivo nuevo que los DTOs de consentimiento médico, ya que semánticamente aplica a `shareMedicalInfo=false` en registrations, pero es un contrato "cross-domain" reutilizable). Se exporta también desde `src/users/dto/index.ts` (ya cubierto por `export * from './dto'` en `src/users/index.ts`, y `src/index.ts` ya hace `export * from './users'`) — sin cambios adicionales de barril necesarios.
3. **Endpoint `POST /users/me/medical-consent` sigue el patrón `updateFcmToken`**: gateway resuelve email autenticado (mismo mecanismo que `GET /users/me`, ya usa `request.user?.email` + 401 si falta), arma payload `{ email, consentVersion }`, `usersService.send('acceptMedicalConsent', payload)`. En `users-ms`, nuevo método de servicio `acceptMedicalConsent(email, consentVersion)`: busca por email (reusa lógica de `findByEmail`), setea `medicalConsentAcceptedAt: new Date()`, retorna `{ medicalConsentAcceptedAt }` (no el user completo, para minimizar payload — criterio de aceptación #8 solo pide ese campo).
4. **`GET /users/me` no requiere cambios de código.** `findUserByEmail` retorna el objeto Prisma `User` completo sin mapeo explícito; al agregar `medicalConsentAcceptedAt` al schema, el campo aparece automáticamente en la respuesta (criterio #9 se satisface solo con la migración).
5. **Registro (`EventRegistration`) — hallazgo crítico no listado en §4 del PRD:** `registrations.service.ts::create()` construye `registrationData` campo-por-campo (no hace spread de `data`), a diferencia de `update()` que sí hace `{ ...rest, status, medicalInsurance }`. Los 4 campos nuevos deben agregarse **explícitamente** en el objeto `registrationData` de `create()` (líneas ~72-87) o nunca llegarán a la DB pese a estar en el DTO. `update()` no necesita cambios (el spread `...rest` ya los propaga). Ver Change map.
6. **`buildOwnerAutoRegistrationCreate` (owner-auto-registration.ts) NO necesita cambios.** El objeto que retorna es un `Omit<...>` sin los 4 campos nuevos; Prisma aplica los `@default(false)` / `null` del schema automáticamente al crear. Confirmado por lectura del archivo — no hace falta tocarlo.
7. **`enrichRegistrationWithVehicle`/`buildVehicleSummary` NO necesitan cambios** — hacen `{ ...registration, vehicleSummary }`, spread completo del registro Prisma, así que los campos nuevos viajan solos en la respuesta una vez persistidos.
8. **`Event.create`/`Event.update` (events.service.ts) NO necesitan cambios de lógica** — ambos hacen `{ ...rest }` / `{ ...restUpdate }` spread del DTO completo hacia Prisma. Agregar `organizerAcceptedResponsibilityAt` a `CreateEventDto` (con `UpdateEventDto = PartialType(CreateEventDto)`) es suficiente; el campo fluye solo.
9. **`riskAcceptedAt`/`riskAcceptanceVersion` `@IsOptional()` en `CreateRegistrationDto`** (y por herencia en `UpdateRegistrationDto`/`*PayloadDto`), sin validar en esta fase que sean requeridos para status APPROVED — eso es Fase 2 (`422 RISK_NOT_ACCEPTED`).
10. **Migraciones:** dos migraciones Prisma independientes (`events-ms`, `users-ms`), cada una en su propio submódulo Git. No se ejecutan en esta fase (`prisma migrate dev` queda para Backend, quien reporta el resultado; Architect solo especifica el DDL esperado en `analysis/MIGRATION_PLAN.md`).

## Change map

| file | action | reason | risk |
|---|---|---|---|
| `rideglory-api/events-ms/prisma/schema.prisma` | modify | Agregar 4 campos a `EventRegistration` (`shareMedicalInfo Boolean @default(false)`, `allowOrganizerContact Boolean @default(false)`, `riskAcceptedAt DateTime?`, `riskAcceptanceVersion String?`) + 1 campo a `Event` (`organizerAcceptedResponsibilityAt DateTime?`) | med |
| `rideglory-api/events-ms/prisma/migrations/<timestamp>_add_medical_consent_risk_fields/migration.sql` | create | Migración generada por `prisma migrate dev --create-only` | med |
| `rideglory-api/users-ms/prisma/schema.prisma` | modify | Agregar `medicalConsentAcceptedAt DateTime?` a `User` | low |
| `rideglory-api/users-ms/prisma/migrations/<timestamp>_add_medical_consent_accepted_at/migration.sql` | create | Migración generada | low |
| `rideglory-api/rideglory-contracts/src/events/dto/create-registration.dto.ts` | modify | Agregar `shareMedicalInfo?: boolean`, `allowOrganizerContact?: boolean`, `riskAcceptedAt?: Date`, `riskAcceptanceVersion?: string` — todos `@IsOptional()` (booleanos con `@IsBoolean()`, fecha con `@Type(() => Date) @IsDate()`, versión con `@IsString()`) | med |
| `rideglory-api/rideglory-contracts/src/events/dto/event-registration.dto.ts` | modify | Agregar los mismos 4 campos como no-opcionales de respuesta (`shareMedicalInfo!: boolean`, `allowOrganizerContact!: boolean`, `riskAcceptedAt!: Date \| null`, `riskAcceptanceVersion!: string \| null`) | low |
| `rideglory-api/rideglory-contracts/src/events/dto/create-event.dto.ts` | modify | Agregar `organizerAcceptedResponsibilityAt?: Date` (`@IsOptional() @Type(() => Date) @IsDate()`); `UpdateEventDto` lo hereda automáticamente vía `PartialType(CreateEventDto)`, sin tocar `update-event.dto.ts` | low |
| `rideglory-api/rideglory-contracts/src/users/dto/medical-consent.dto.ts` | create | Nuevo: `MedicalConsentDto` (request, `consentVersion: string` `@IsString() @MinLength(1)`), `MedicalConsentResponseDto` (response, `medicalConsentAcceptedAt: Date`), constante `export const NOT_SHARED_SENTINEL = '__NOT_SHARED__' as const;` | low |
| `rideglory-api/rideglory-contracts/src/users/dto/index.ts` | modify | `export * from './medical-consent.dto';` | low |
| `rideglory-api/rideglory-contracts/src/users/dto/create-user.dto.ts` | none (verificado, sin cambios) | `medicalConsentAcceptedAt` no aplica a alta de perfil por firma — se acepta solo vía endpoint dedicado | — |
| `rideglory-api/users-ms/src/users/users.controller.ts` | modify | Agregar `@MessagePattern('acceptMedicalConsent') acceptMedicalConsent(@Payload() payload: { email: string; consentVersion: string })` | low |
| `rideglory-api/users-ms/src/users/users.service.ts` | modify | Agregar método `acceptMedicalConsent(email: string, consentVersion: string)`: `findByEmail` + `update` seteando `medicalConsentAcceptedAt: new Date()`; retorna `{ medicalConsentAcceptedAt }`. `consentVersion` no se persiste en `users-ms` (no hay columna para versión en `User`; el schema del PRD solo pide `medicalConsentAcceptedAt`) — **decisión:** loguear `consentVersion` a nivel de `Logger.log` para auditoría hasta que exista almacenamiento de versión (fuera de alcance de esta fase, no hay campo en el schema) | med |
| `rideglory-api/api-gateway/src/users/users.controller.ts` | modify | Agregar `@Post('me/medical-consent') acceptMedicalConsent(@Req() request, @Body() dto: MedicalConsentDto)` — reusa el mismo patrón de `findMe` para resolver `email` y lanzar `UnauthorizedException` si falta; `usersService.send('acceptMedicalConsent', { email, consentVersion: dto.consentVersion })` | med |
| `rideglory-api/events-ms/src/registrations/registrations.service.ts` | modify | **Hallazgo no listado en §4 del PRD original.** En `create()`, agregar los 4 campos nuevos al objeto `registrationData` (líneas ~72-87) leyendo de `data.shareMedicalInfo`, `data.allowOrganizerContact`, `data.riskAcceptedAt`, `data.riskAcceptanceVersion` (con `?? false` para los booleanos, `?? null` para fecha/versión). `update()` no requiere cambio (ya spreadea `...rest`) | high |
| `rideglory-api/events-ms/src/events/owner-auto-registration.ts` | none (verificado, sin cambios) | Prisma aplica defaults (`false`/`null`) automáticamente al omitir los campos del `Omit<...>` de auto-registro del organizador | — |
| `rideglory-api/events-ms/src/events/events.service.ts` | none (verificado, sin cambios) | `create`/`update` ya spreadean el DTO completo hacia Prisma | — |

**Fuera de la lista = Build no lo toca.** Cualquier archivo adicional que Backend considere necesario debe volver a este agente para actualizar el change map.

## Contratos (rideglory-api)

| Method | Path | Auth | Request body | Success | Errors |
|---|---|---|---|---|---|
| POST | `/users/me/medical-consent` | Firebase ID token (guard global `APP_GUARD` en api-gateway) | `MedicalConsentDto { consentVersion: string }` | 201 `MedicalConsentResponseDto { medicalConsentAcceptedAt: string (ISO) }` | 401 si no hay email válido en JWT; 404 si el usuario no existe en `users-ms` (mismo comportamiento que `findByEmail` actual, que lanza `RpcException NOT_FOUND`) |
| GET | `/users/me` | Firebase ID token | — | 200, ahora incluye `medicalConsentAcceptedAt: string \| null` | sin cambios de contrato de error |
| POST | `/events/:id/registrations` (ya existe, sin cambio de ruta) | Firebase ID token | `CreateRegistrationDto` ampliado con 4 campos opcionales | 201, `EventRegistrationDto` ampliado | sin cambios de error en esta fase |
| PATCH/POST `/events` (ya existe) | Firebase ID token | `CreateEventDto`/`UpdateEventDto` con `organizerAcceptedResponsibilityAt?` | 200/201 | sin cambios |

**Message patterns internos (RabbitMQ/TCP, no HTTP):** `acceptMedicalConsent` (nuevo, `users-ms`); `createRegistration`, `updateRegistration`, `createEvent`, `updateEvent` (existentes, sin cambio de nombre — solo payload ampliado).

## Datos/migraciones

Ver `analysis/MIGRATION_PLAN.md` para el DDL detallado. Resumen:
- `events-ms`: `ALTER TABLE "EventRegistration" ADD COLUMN "shareMedicalInfo" BOOLEAN NOT NULL DEFAULT false, ADD COLUMN "allowOrganizerContact" BOOLEAN NOT NULL DEFAULT false, ADD COLUMN "riskAcceptedAt" TIMESTAMP(3), ADD COLUMN "riskAcceptanceVersion" TEXT;` + `ALTER TABLE "Event" ADD COLUMN "organizerAcceptedResponsibilityAt" TIMESTAMP(3);`
- `users-ms`: `ALTER TABLE "User" ADD COLUMN "medicalConsentAcceptedAt" TIMESTAMP(3);`
- Ambas son additive, nullable o con default seguro — no requieren backfill ni downtime. No se ejecutan en esta fase (Backend corre `prisma migrate dev --create-only` y reporta status; el humano decide cuándo aplicar contra DB real).

## Env

Sin variables de entorno nuevas. No se genera `analysis/ENV_DELTA.md` (no aplica).

## Riesgos

- **Alto — `registrations.service.ts::create()` construcción manual del objeto (hallazgo #5 arriba).** Si Backend solo toca el DTO y el schema sin tocar este archivo, los criterios de aceptación #5/#6 del PRD fallan silenciosamente (201 pero campos no persistidos). Marcado `risk: high` en change map, debe ser lo primero que QA verifique.
- **Medio — orden del gotcha de contratos.** Si `pnpm install` corre en algún MS antes de `npm run build` en `rideglory-contracts`, falla con `MODULE_NOT_FOUND`. Orden obligatorio: contracts build → events-ms/users-ms/api-gateway install.
- **Medio — `consentVersion` no tiene columna de persistencia en `users-ms`.** El PRD solo pide `medicalConsentAcceptedAt` en el schema (criterio #1 events-ms, #2 users-ms no menciona columna de versión). Se decide loguear la versión sin persistirla estructuralmente; si el negocio necesita auditoría de versión más adelante, requiere una fase futura con nueva columna — documentado, no bloqueante para esta fase.
- **Bajo — `bloodType: BloodType | string`.** No aplica en esta fase (ver Decisión #1); si una fase futura lo introduce, revisar `switch/case` sobre `bloodType` en `events-ms` como advierte el guardrail #6 del PRD.
- **Bajo — dos submódulos Git independientes con migraciones distintas.** Backend debe generar y aplicar cada migración por separado, con su propio commit en cada submódulo (fuera del alcance de commit de este workflow; el humano commitea).

## Orden de implementación

1. `rideglory-contracts`: schema DTOs (`create-registration.dto.ts`, `event-registration.dto.ts`, `create-event.dto.ts`, nuevo `medical-consent.dto.ts` + `index.ts`) → `npm run build`.
2. `events-ms`: `prisma/schema.prisma` (5 campos) → `prisma migrate dev --create-only` (o el comando que Backend decida sin aplicar en prod) → `pnpm install` (para tomar el contracts recién buildeado) → `registrations.service.ts::create()` (agregar los 4 campos al objeto `registrationData`) — **este paso no debe omitirse**.
3. `users-ms`: `prisma/schema.prisma` (1 campo) → migración → `pnpm install` → `users.service.ts` (`acceptMedicalConsent`) → `users.controller.ts` (`@MessagePattern('acceptMedicalConsent')`).
4. `api-gateway`: `pnpm install` (tomar contracts) → `users.controller.ts` (`POST /users/me/medical-consent`).
5. Verificación manual/QA: `prisma migrate status` en ambos MS, `npm run build` en contracts (exit 0), `pnpm run start:dev` en los 3 MS sin `MODULE_NOT_FOUND`, smoke test de los 10 criterios de aceptación del PRD.

## Superficie de regresión

- `EventRegistrationDto` gana 4 campos no-opcionales de respuesta — cualquier consumidor TS que construya el objeto a mano (no debería haber ninguno fuera de `registrations.service.ts`, que spreadea Prisma) falla de compilación si no los provee. Revisado: no hay otros constructores manuales de `EventRegistrationDto` en el repo backend.
- `CreateEventDto`/`UpdateEventDto`: campo nuevo opcional, no rompe payloads existentes sin el campo.
- `User` (Prisma, users-ms): campo nuevo nullable, no rompe `create`/`update` existentes.
- Ningún cambio de ruta ni de nombre de message pattern existente — solo adiciones. Sin impacto en Flutter (`lib/`) en esta fase.

## Fuera de alcance (recordatorio explícito)

- `422 RISK_NOT_ACCEPTED`, ofuscación condicional `UNDERAGE_RIDER`, cualquier lógica de negocio sobre los campos nuevos → Fase 2.
- Modelos/DTOs Flutter, UI de waiver, Ley 1581 → Fases 3-6.
- Tests unitarios de lógica de negocio de inscripciones → Fase 2 (esta fase solo requiere que compile y persista).
- Ejecutar migraciones contra DB real, commitear, o abrir PRs — el humano lo hace tras revisión.

## Change log
- 2026-07-01T01:34:57Z: Architect phase completa. §4 del PRD corregido contra código real: agregado hallazgo crítico en `registrations.service.ts::create()` (construcción manual de objeto, no listado originalmente). Confirmado que `events.service.ts`, `owner-auto-registration.ts` y `enrichRegistrationWithVehicle` no requieren cambios (spread completo). Contratos, migraciones y endpoint `medical-consent` especificados.
