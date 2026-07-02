# PRD Normalizado — Fase 1: Contratos, schema de backend y endpoint medical-consent

**Slug:** `legal-privacidad-edad-fase1`
**Fuente:** `docs/plans/legal-privacidad-edad/phases/phase-01-contratos-schema-de-backend-y-endpoint-medical-c.md`
**Timestamp normalización:** 2026-07-01T01:32:50Z

---

## 1 Objetivo

Habilitar en el backend (`rideglory-api`) toda la infraestructura de datos que las fases 2-7 del plan `legal-privacidad-edad` necesitan: migraciones Prisma en `events-ms` (4 campos nuevos en `EventRegistration` + 1 en `Event`) y en `users-ms` (1 campo en `User`), actualización del submódulo `rideglory-contracts` con los DTOs ampliados y dos nuevos contratos de consentimiento médico, y el nuevo endpoint `POST /users/me/medical-consent`. Al cierre de la fase, el backend debe poder recibir y persistir todos los campos legales nuevos, con los contratos compilados y disponibles en todos los microservicios afectados.

## 2 Por que

El plan `legal-privacidad-edad` necesita soportar consentimiento médico, privacidad de datos sensibles (ofuscación condicional), aceptación de riesgo en inscripciones y responsabilidad del organizador. Todo eso depende de que el schema de datos y los contratos TypeScript existan primero; sin esta fase base, las fases 2 (validación de edad/ofuscación), 3 (modelos Flutter), 5 (responsabilidad del organizador) y 6 (Ley 1581) quedan bloqueadas.

## 3 Alcance

### Entra
- Migración Prisma en `events-ms`: 4 campos en `EventRegistration` (`shareMedicalInfo`, `allowOrganizerContact`, `riskAcceptedAt`, `riskAcceptanceVersion`) + 1 campo `organizerAcceptedResponsibilityAt` en `Event`.
- Migración Prisma en `users-ms`: campo `medicalConsentAcceptedAt DateTime?` en `User`.
- `rideglory-contracts`: ampliar `CreateRegistrationDto`, `EventRegistrationDto`, `CreateEventDto`/`UpdateEventDto`; agregar `MedicalConsentDto` y `MedicalConsentResponseDto`.
- Nuevo endpoint `POST /users/me/medical-consent` en `users-ms` + exposición REST en `api-gateway`.
- `GET /users/me` debe retornar `medicalConsentAcceptedAt`.
- Fijar el centinela semántico `"__NOT_SHARED__"` como constante documentada (`NOT_SHARED_SENTINEL`) en contratos.
- Seguir el gotcha de rebuild de contratos: `npm run build` en `rideglory-contracts` + `pnpm install` en `events-ms`, `users-ms` y `api-gateway`.

### No entra (diferido a fases posteriores)
- Lógica de validación de edad (`UNDERAGE_RIDER`) → Fase 2.
- Lógica de ofuscación condicional en `findByEvent` → Fase 2.
- Validación de negocio `422 RISK_NOT_ACCEPTED` → Fase 2.
- Modelos y DTOs Flutter → Fase 3.
- UI de waiver, pantalla de responsabilidad del organizador, Ley 1581 → Fases 4-6.
- Tests unitarios de lógica de negocio de inscripciones → Fase 2.

## 4 Areas afectadas (best-effort)

- `rideglory-api/events-ms/prisma/schema.prisma` (+ migración generada)
- `rideglory-api/users-ms/prisma/schema.prisma` (+ migración generada)
- `rideglory-api/users-ms/src/users/users.controller.ts`
- `rideglory-api/users-ms/src/users/users.service.ts`
- `rideglory-api/api-gateway/src/users/users.controller.ts`
- `rideglory-api/rideglory-contracts/src/events/dto/create-registration.dto.ts`
- `rideglory-api/rideglory-contracts/src/events/dto/event-registration.dto.ts`
- `rideglory-api/rideglory-contracts/src/events/dto/create-event.dto.ts`
- `rideglory-api/rideglory-contracts/src/users/dto/medical-consent.dto.ts` (nuevo)
- `rideglory-api/rideglory-contracts/src/users/dto/index.ts`

Nota: este trabajo es 100% backend (repo `rideglory-api`, separado de este worktree Flutter). No toca `lib/` de Rideglory.

## 5 Criterios de aceptacion

1. **Migración events-ms aplicada:** `prisma migrate status` en `events-ms` reporta "Database schema is up to date". Las 5 columnas nuevas existen en las tablas `EventRegistration` y `Event`.
2. **Migración users-ms aplicada:** `prisma migrate status` en `users-ms` reporta "Database schema is up to date". La columna `medicalConsentAcceptedAt` existe en `User`.
3. **Contratos compilados sin errores:** `npm run build` en `rideglory-contracts` termina con código de salida 0, sin errores de TypeScript.
4. **Dependencias resueltas en todos los MS:** `pnpm install` en `events-ms`, `users-ms` y `api-gateway` termina sin errores; los servicios levantan con `pnpm run start:dev` sin `MODULE_NOT_FOUND`.
5. **CreateRegistrationDto acepta los 4 campos:** `POST /events/:id/registrations` con `shareMedicalInfo`, `allowOrganizerContact`, `riskAcceptedAt`, `riskAcceptanceVersion` retorna 201 (no 400) y persiste los valores en DB.
6. **EventRegistrationDto de respuesta incluye los 4 campos:** `GET /events/:id/registrations` retorna los 4 campos nuevos por inscripción; para inscripciones pre-migración, los booleanos son `false` y las fechas/versión son `null`.
7. **CreateEventDto acepta organizerAcceptedResponsibilityAt:** `POST /events` o `PATCH /events/:id` con este campo retorna 201/200 y lo persiste.
8. **Endpoint medical-consent funciona:** `POST /users/me/medical-consent` autenticado con `{ consentVersion }` retorna 201 con `{ medicalConsentAcceptedAt }`, persistido en DB.
9. **GET /users/me retorna medicalConsentAcceptedAt:** presente en la respuesta (puede ser `null`).
10. **NOT_SHARED_SENTINEL exportado:** constante `NOT_SHARED_SENTINEL = '__NOT_SHARED__'` exportada desde contratos e importable sin errores de compilación desde `events-ms` y `users-ms`.

## 6 Guardrails de regresion

- No implementar en esta fase la validación de negocio `422 RISK_NOT_ACCEPTED` ni la lógica de ofuscación condicional (`UNDERAGE_RIDER`) — quedan explícitamente para Fase 2; el campo `riskAcceptedAt` debe ser `@IsOptional()` en el contrato.
- No tocar modelos/DTOs Flutter ni UI (waiver, responsabilidad del organizador, Ley 1581) — fuera de alcance (Fases 3-6).
- No romper el campo `sosTriggeredAt` existente en `Event` (ya existe, línea ~77 del schema) — solo agregar `organizerAcceptedResponsibilityAt`.
- Los defaults de los booleanos nuevos (`shareMedicalInfo`, `allowOrganizerContact`) deben ser `false` con `DEFAULT false` explícito en SQL — comportamiento seguro para registros pre-migración (no compartir datos médicos por defecto).
- `riskAcceptedAt` y `riskAcceptanceVersion` deben quedar nullable sin default en Prisma (válido para históricos).
- El cambio de tipo `bloodType: BloodType | string` en `EventRegistorationDto` no debe romper la compilación de TypeScript en consumidores (`events-ms`); revisar cualquier `switch/case` sobre `bloodType`.
- Seguir estrictamente el orden del gotcha de contratos (`npm run build` en `rideglory-contracts` antes de `pnpm install` en cada MS) para evitar `MODULE_NOT_FOUND`.
- El endpoint `POST /users/me/medical-consent` debe seguir el patrón de autenticación Firebase existente en el gateway (401 si no hay email válido en el JWT).
- No commitear cambios (working tree queda sucio para revisión humana) — regla dura del proceso rg-exec.
- No modificar `docs/PRD.md`, `docs/PLAN.md`, `docs/PRODUCT_STATUS.md`, `docs/handoffs/**`, `.claude/**`, ni la nota fuente del plan.

## 7 Constraints heredados

- Repo backend real: `rideglory-api` está en `/Users/cami/Developer/Personal/rideglory-api` (repo separado del worktree Flutter actual); es un super-repo con submódulos independientes (`events-ms`, `users-ms`, `api-gateway`, `rideglory-contracts` cada uno su propio repo Git).
- Gotcha de rebuild de contratos (`project_contracts_rebuild_gotcha.md`): al cambiar `@rideglory/contracts` siempre `npm run build` + `pnpm install` en cada MS consumidor, o fallan con `MODULE_NOT_FOUND`.
- Sin usuarios reales en producción (`project_no_real_users.md`): refactors agresivos y defaults retroactivos son aceptables sin riesgo productivo, pero deben documentarse para cuando existan usuarios reales.
- `Event.sosTriggeredAt` ya existe en el schema de `events-ms` — no debe re-agregarse ni duplicarse.
- DTO write payloads deben usar `.toJson()` de contratos (regla general del proyecto para consumo Flutter en fases posteriores; no aplica directamente al backend TS pero condiciona el diseño del contrato para que Fase 3 lo consuma correctamente).
- Nivel de ejecución recomendado por el plan de origen: `full` (justificado por: 2 microservicios con migraciones distintas, submódulo de contratos que bloquea fases 2-7 si falla, campos PII con defaults retroactivos, edge case sutil de `riskAcceptedAt` nullable en DB vs obligatorio en negocio, alto blast radius de errores).
