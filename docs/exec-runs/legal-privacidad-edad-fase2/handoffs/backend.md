# Backend handoff — legal-privacidad-edad-fase2

**Date:** 2026-07-01T04:25:27Z
**Status:** done
**Repo:** `/Users/cami/Developer/Personal/rideglory-api` (submodule `events-ms`)

## Baseline

`git status` in `events-ms` was clean before starting (3 local commits ahead of origin, no uncommitted changes). Baseline run:

```
cd events-ms && npx jest registrations.service
Test Suites: 1 passed, 1 total
Tests:       2 passed, 2 total
```

Green baseline — proceeded with implementation.

## Archivos cambiados

- `events-ms/src/registrations/registrations.service.ts` (modify)
  - Added `EventState` to the existing `PrismaClient` import from `../generated/prisma`.
  - `create()`: inserted `this.ensureRiderIsAdult(data.birthDate);` between `ensureUserHasNoActiveRegistration()` and `ensureVehicleIdForNonOwner()`, preserving the pre-existing call order.
  - New private `ensureRiderIsAdult(birthDate: Date): void` — year/month/day age computation; throws `RpcException({ status: HttpStatus.UNPROCESSABLE_ENTITY, message: 'UNDERAGE_RIDER' })` when age < 18. Not applied in `update()` (out of scope, per PRD/architect).
  - `findByEvent()`: now captures `event` from `ensureEventExists()` (previously discarded) and maps `enrichRegistrationsWithVehicle` output through the new `applyPrivacyMask(registration, event)` per registration.
  - New private `applyPrivacyMask<T extends {...}>(registration: T, event: { state: EventState; sosTriggeredAt: Date | null }): T` — generic bound types `bloodType` as `string` (not the Prisma `BloodType` enum) per guardrail R1. Applies the 4-layer masking table verbatim (medical fields / emergency contact / phone / SOS-PII), sentinels `"__NOT_SHARED__"` and `"••••"` exactly as specified. `medicalInsurance` masked value is always the string `'__NOT_SHARED__'`, never `null`.
  - `findMyRegistrationForEvent()` and `findMyRegistrations()` untouched — no masking applied (per scope).
- `events-ms/src/registrations/registrations.service.age-validation.spec.ts` (create)
- `events-ms/src/registrations/registrations.service.privacy-mask.spec.ts` (create)

No changes to `schema.prisma`, `prisma/migrations/`, `registrations.controller.ts`, `registrations.module.ts`, or `rideglory-contracts` — none were needed (pre-flight gates from the architect handoff already confirmed `sosTriggeredAt` and the 4 Fase 1 fields exist).

## Pruebas nuevas

**`registrations.service.age-validation.spec.ts`** (4 cases, mocks `usersService`/`vehiclesService` as two separate `ClientProxy` mocks, per R3):
1. 17y364d birthdate → `create()` rejects with `RpcException` `status: 422`, `message: 'UNDERAGE_RIDER'`; `upsert` never called.
2. Exactly-18-today birthdate → `create()` resolves, `upsert` called.
3. Comfortably-over-18 (1990-01-01) → `create()` resolves.
4. Comfortably-under-18 (15y) → `create()` rejects with same 422/`UNDERAGE_RIDER`.

**`registrations.service.privacy-mask.spec.ts`** (5 cases, calls `findByEvent()` directly to prove wiring):
1. `SCHEDULED` event + `shareMedicalInfo=true` → `eps`/`medicalInsurance`/`bloodType` masked to `"__NOT_SHARED__"` regardless; `vehicleSummary` asserted present (proves mask runs after `enrichRegistrationsWithVehicle`).
2. `IN_PROGRESS` + `shareMedicalInfo=true` → medical fields real.
3. `IN_PROGRESS` + `shareMedicalInfo=false` → medical fields masked.
4. `allowOrganizerContact` false/true (two registrations in one `findMany` call) → `phone` masked (`"••••"`) / real respectively.
5. `sosTriggeredAt` null → `identificationNumber`/`email`/`residenceCity` masked (`"••••"`); re-run with `sosTriggeredAt` set → real values.

## Resultado final

```
cd events-ms && npx tsc --noEmit
→ 0 errors

npx jest registrations.service.age-validation registrations.service.privacy-mask
Test Suites: 2 passed, 2 total
Tests:       9 passed, 9 total

npx jest registrations.service   (full existing + new specs, regression check)
Test Suites: 3 passed, 3 total
Tests:       11 passed, 11 total

npx jest   (full events-ms suite)
Test Suites: 5 passed, 5 total
Tests:       42 passed, 42 total
# Actualizado 2026-07-01 (post-integración de otras fases): 6 suites / 48 tests / 0 failures
```

No regressions in any pre-existing spec (`registrations.service.spec.ts` — the medical-consent persistence tests still pass unchanged since their `birthDate` fixture, 1990-01-01, is well above 18).

## Verificacion manual

Not applicable — no server/DB was started; this phase is fully covered by unit tests + `tsc --noEmit` per the architect's plan (no Patrol/e2e needed, backend-only, no UI). Acceptance criteria 1, 2, 10, 12 (PRD §5) are directly asserted by the new specs and `tsc --noEmit`. Criteria 3-9 (masking table combinations) and 11 (`findMyRegistrationForEvent`/`findMyRegistrations` unmasked) are covered by the privacy-mask spec plus the untouched behavior of those two methods (no code path change — verified by reading the final file, they still call `enrichRegistrationsWithVehicle` directly with no `applyPrivacyMask` step).

## Notas Frontend/QA

- **Frontend (Fases 3-7):** zero Flutter changes in this phase (confirmed, stand down per architect handoff). When those phases consume `GET /events/:eventId/registrations`, expect the sentinel strings `"__NOT_SHARED__"` (medical fields) and `"••••"` (PII/contact fields) in place of real values under the documented conditions — see masking table in PRD §5. `POST .../registrations` (create) can now return `422 UNDERAGE_RIDER` (message field, not `code`) when the rider is under 18 — Fase 4 should surface this.
- **Known pre-existing contract drift (non-blocking, flagged by architect):** `EventRegistrationDto.bloodType` in `rideglory-contracts` is still strictly typed `BloodType` (not widened to `BloodType | string` as the original PRD assumed). It is not used as a type annotation anywhere in `events-ms`/`api-gateway` response paths today, so this phase's `tsc --noEmit` is clean. However, before Flutter Fases 3-7 consume this contract and try to deserialize the sentinel `"__NOT_SHARED__"` into a `BloodType` enum field, `rideglory-contracts` will need a follow-up fix to widen that type. Recommend a small follow-up ticket before Fase 3-7 backend-contract work.
- **QA:** primary verification surface is the two new spec files (9 tests) + `tsc --noEmit`, all green. No Patrol/e2e required — backend-only phase, no UI touched.
