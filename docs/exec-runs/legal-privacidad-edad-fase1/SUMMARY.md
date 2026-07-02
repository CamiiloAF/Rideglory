# SUMMARY — legal-privacidad-edad-fase1

**Fecha:** 2026-07-01T02:00:34Z
**Nivel:** normal
**Repos afectados:** `rideglory-api` (super-repo, submódulos `rideglory-contracts`, `events-ms`, `users-ms`, `api-gateway`). El worktree Flutter (`lib/`) no fue tocado — fase 100% backend.

## Objetivo

Habilitar en `rideglory-api` la infraestructura de datos base (migraciones Prisma + contratos TypeScript + endpoint) que las fases 2-7 del plan `legal-privacidad-edad` necesitan: 4 campos nuevos en `EventRegistration`, 1 campo en `Event`, 1 campo en `User`, contratos ampliados (`CreateRegistrationDto`, `EventRegistrationDto`, `CreateEventDto`) y dos DTOs nuevos de consentimiento médico, más el endpoint `POST /users/me/medical-consent`.

## Que cambio por area

### `rideglory-contracts`
- `create-registration.dto.ts`: +4 campos opcionales (`shareMedicalInfo`, `allowOrganizerContact`, `riskAcceptedAt`, `riskAcceptanceVersion`), todos `@IsOptional()` (booleanos, fecha, string), consistente con que la validación de negocio `422 RISK_NOT_ACCEPTED` es de Fase 2.
- `event-registration.dto.ts`: mismos 4 campos como respuesta no-opcional (booleanos, fecha/versión nullable).
- `create-event.dto.ts`: `organizerAcceptedResponsibilityAt?: Date`; `UpdateEventDto` lo hereda vía `PartialType`.
- `src/users/dto/medical-consent.dto.ts` (nuevo): `MedicalConsentDto` (request), `MedicalConsentResponseDto` (response), `NOT_SHARED_SENTINEL = '__NOT_SHARED__'` exportado para uso de Fase 2 (ofuscación condicional).
- `src/users/dto/index.ts`: export del nuevo archivo.
- `npm run build` → exit 0.

### `events-ms`
- `prisma/schema.prisma`: 4 campos nuevos en `EventRegistration` (booleanos `@default(false)`, fecha/versión nullable sin default) + `organizerAcceptedResponsibilityAt DateTime?` en `Event` (no se tocó `sosTriggeredAt`, verificado intacto).
- Migración `20260701014208_add_medical_consent_risk_fields` — DDL additivo, aplicada a la DB local de dev (drift pre-existente no relacionado obligó a aplicar el SQL manualmente vía `prisma db execute` + `migrate resolve --applied`, documentado en el handoff de backend).
- `src/registrations/registrations.service.ts::create()`: se agregaron explícitamente los 4 campos nuevos al objeto `registrationData`. Este es el **hallazgo crítico del architect**: el objeto se construye campo-por-campo sin spread del DTO, a diferencia de `update()` que sí spreadea — sin este cambio los campos pasaban la validación pero nunca se persistían. Verificado correcto en el diff.
- `src/registrations/registrations.service.spec.ts` (nuevo): 2 tests que ejercitan `create()` real (Prisma mockeado) y verifican el payload exacto enviado a `upsert()`, tanto con los campos presentes como omitidos (defaults `false`/`false`/`null`/`null`).

### `users-ms`
- `prisma/schema.prisma`: `medicalConsentAcceptedAt DateTime?` en `User`.
- Migración `20260701014335_add_medical_consent_accepted_at` — DDL additivo, flujo estándar sin drift.
- `src/users/users.service.ts`: nuevo método `acceptMedicalConsent(email, consentVersion)` — reusa `findByEmail` (lanza `RpcException NOT_FOUND` si no existe), setea `medicalConsentAcceptedAt = new Date()`, loguea `consentVersion` (no persistido; no hay columna de versión en el schema, decisión documentada por el architect como riesgo medio no bloqueante), retorna `{ medicalConsentAcceptedAt }`.
- `src/users/users.controller.ts`: `@MessagePattern('acceptMedicalConsent')`.
- `src/users/users.service.spec.ts` (nuevo): 2 tests (persiste y retorna; `RpcException` si el usuario no existe).

### `api-gateway`
- `src/users/users.controller.ts`: `POST /users/me/medical-consent`, mismo patrón de auth que `findMe` (401 vía `UnauthorizedException` si no hay email en el JWT autenticado; sin `@Public()`).
- `src/users/users.controller.spec.ts` (nuevo): 2 tests (reenvía email+consentVersion al MS; 401 si falta email).

## Archivos

**`rideglory-contracts`** (modificados): `src/events/dto/create-registration.dto.ts`, `src/events/dto/event-registration.dto.ts`, `src/events/dto/create-event.dto.ts`, `src/users/dto/index.ts`
**`rideglory-contracts`** (nuevo): `src/users/dto/medical-consent.dto.ts`

**`events-ms`** (modificados): `prisma/schema.prisma`, `src/registrations/registrations.service.ts`
**`events-ms`** (nuevos): `prisma/migrations/20260701014208_add_medical_consent_risk_fields/migration.sql`, `src/registrations/registrations.service.spec.ts`

**`users-ms`** (modificados): `prisma/schema.prisma`, `src/users/users.controller.ts`, `src/users/users.service.ts`
**`users-ms`** (nuevos): `prisma/migrations/20260701014335_add_medical_consent_accepted_at/migration.sql`, `src/users/users.service.spec.ts`

**`api-gateway`** (modificado): `src/users/users.controller.ts`
**`api-gateway`** (nuevo): `src/users/users.controller.spec.ts`

**Worktree Flutter (`Rideglory`):** sin cambios en `lib/`; solo el directorio `docs/exec-runs/legal-privacidad-edad-fase1/` (documentación de esta corrida).

**Fuera del change map, pre-existentes en el working tree compartido de `rideglory-api` (no tocados ni revisados por esta fase, confirmado por diff):** `events-ms/src/events/events.service.ts` + `events.controller.ts` (cron de tracking, `IN_PROGRESS`/`forceEndTracking`), `rideglory-contracts/src/events/dto/event-filter.dto.ts` (`authUserId`), `api-gateway/src/home/home.controller.ts`, `api-gateway/src/tracking/tracking-http.controller.ts`. Pertenecen a otra fase/sesión en curso sobre el mismo super-repo.

## Pruebas

- `rideglory-contracts`: `npm run build` → exit 0 (antes y después).
- `events-ms`: `npx jest` → 3 failed (mismos rojos pre-existentes en `events.service.spec.ts`, TC-6/7/8 sobre `findUpcoming`, no relacionados), 23 passed (antes: 21) — +2 tests nuevos verdes.
- `users-ms`: `npx jest` → antes "No tests found"; después 1 suite, 2 passed.
- `api-gateway`: `npx jest` → 8 failed (mismos rojos pre-existentes en `places.service.iter3.spec.ts`, geocoding, no relacionados), 103 passed (antes: 101) — +2 tests nuevos verdes.
- `npx tsc --noEmit` y `nest build` sin errores en los 3 MS.
- `prisma migrate status` → "up to date" en `events-ms` y `users-ms`; columnas verificadas vía `psql \d` (tipos/nullability/defaults correctos).
- QA re-corrió y confirmó los mismos conteos (ver `handoffs/qa.md`); sign-off **green** con 2 gaps de cobertura no bloqueantes documentados (AC #6 `GET registrations` con defaults pre-migración, AC #7 `organizerAcceptedResponsibilityAt` en `POST/PATCH events` — solo cobertura indirecta vía schema/DTO, sin test dedicado).

## Riesgos/watchlist

- **Gap de test:** AC #6 (defaults correctos en `GET /events/:id/registrations` para registros pre-migración) y AC #7 (`organizerAcceptedResponsibilityAt` persistido vía `POST/PATCH /events`) no tienen test unitario ni E2E dedicado, solo cobertura indirecta (schema con defaults SQL correctos + DTOs con spread completo verificado por lectura de código). Riesgo bajo pero real; recomendable cerrarlo en Fase 2 o antes.
- **`consentVersion` no se persiste estructuralmente** en `users-ms` (solo se loguea) — no hay columna en el schema para ello; si el negocio requiere auditoría de versión de consentimiento más adelante, se necesita una fase futura con nueva columna.
- **No hubo smoke E2E HTTP con JWT Firebase real** para `POST /events/:id/registrations` ni `POST /users/me/medical-consent` — se evitó reiniciar servidores activos de otra sesión de desarrollo en los mismos puertos. La persistencia crítica (AC #5, el hallazgo del architect) sí está cubierta por test unitario que ejercita el código real de `create()`.
- **Drift pre-existente en `events-ms`** (migración `20260611000000_remove_event_city` modificada post-aplicación, no relacionado con esta fase) obligó a aplicar el DDL manualmente en vez del flujo estándar `prisma migrate dev`. Documentado por backend; el humano debe estar al tanto de este drift para futuras migraciones en `events-ms`.
- El working tree de `rideglory-api` tiene cambios sin commitear de **otra fase/sesión no relacionada** (tracking cron, `authUserId` en filtros, home/tracking controllers) — no fueron tocados por esta fase pero conviven en el mismo árbol sucio; al commitear, separar cuidadosamente por fase/feature.
- `bloodType: BloodType | string` — guardrail preventivo del PRD, no aplicado en esta fase (el tipo sigue siendo `BloodType` estricto); queda como advertencia latente si una fase futura lo introduce.

## Mensaje de commit sugerido

Dado que hay múltiples submódulos independientes, se sugiere un commit por submódulo tocado:

**`rideglory-contracts`:**
```
feat(contracts): agregar campos de consentimiento médico y responsabilidad del organizador

Amplía CreateRegistrationDto/EventRegistrationDto con shareMedicalInfo,
allowOrganizerContact, riskAcceptedAt y riskAcceptanceVersion; agrega
organizerAcceptedResponsibilityAt a CreateEventDto; nuevo MedicalConsentDto/
MedicalConsentResponseDto y NOT_SHARED_SENTINEL para consentimiento médico.
Base de datos para las fases 2-7 del plan legal-privacidad-edad.
```

**`events-ms`:**
```
feat(registrations): persistir campos de consentimiento médico y riesgo

Migración additiva en EventRegistration (shareMedicalInfo, allowOrganizerContact,
riskAcceptedAt, riskAcceptanceVersion) y Event (organizerAcceptedResponsibilityAt).
Corrige registrations.service.ts::create() para incluir explícitamente los
campos nuevos en el objeto de persistencia (se construye sin spread del DTO).
```

**`users-ms`:**
```
feat(users): endpoint interno acceptMedicalConsent

Migración additiva (medicalConsentAcceptedAt en User) + método de servicio
y message pattern para registrar la aceptación del consentimiento médico.
```

**`api-gateway`:**
```
feat(users): exponer POST /users/me/medical-consent

Nuevo endpoint autenticado (mismo patrón que GET /users/me) que reenvía
el consentimiento médico del usuario a users-ms.
```
