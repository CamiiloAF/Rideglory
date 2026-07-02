# Architect handoff — legal-privacidad-edad-fase2

**Date:** 2026-07-01T04:19:30Z
**Status:** done

## Pre-flight gate result (blocking checks from PRD §3)

Both hard gates from the PRD are **already satisfied in the current codebase** — verified by reading the files directly, not assumed from the plan:

- `Event.sosTriggeredAt DateTime?` exists at `events-ms/prisma/schema.prisma:77`. **No migration needed.**
- Fase 1 fields on `EventRegistration` all exist at `events-ms/prisma/schema.prisma:102-105`: `shareMedicalInfo Boolean @default(false)`, `allowOrganizerContact Boolean @default(false)`, `riskAcceptedAt DateTime?`, `riskAcceptanceVersion String?`.

Result: `dbChanges = false`. Build does **not** touch `schema.prisma` or `prisma/migrations/` in this phase — that's contingency-only per the PRD and the contingency does not apply.

## §4 correction against reality

One claim in the PRD source is **not accurate** and must be corrected: "No entra: Cambios en `rideglory-contracts` (ya cerrados en Fase 1, incluyendo `bloodType: BloodType | string`)". I read `rideglory-contracts/src/events/dto/event-registration.dto.ts:21` — it still declares `bloodType!: BloodType;` (strict enum), not `BloodType | string`. This was **not** closed in Fase 1 as claimed.

This does **not** block the phase: `EventRegistrationDto` is only defined in the contracts package and referenced in its own file — it is never imported/used as a return-type annotation anywhere in `events-ms` or `api-gateway` (verified with `grep -rln "EventRegistrationDto"`, only hit is the definition file). Both the events-ms controller (`registrations.controller.ts`) and the api-gateway controller (`registrations.controller.ts`) pass the RPC payload through untyped/inferred, so `npx tsc --noEmit` in `events-ms` will not see this mismatch. The type-widening requirement (R1 guardrail) only needs to hold **inside `registrations.service.ts`**, on the `applyPrivacyMask` method signature itself. Flagged as an out-of-scope contract drift; not a blocker for this phase, but worth a follow-up ticket before Fase 3-7 (Flutter) consumes this contract, since Flutter DTOs will type-check against the stale `BloodType` enum.

## Feature architecture decisions

| Feature | Domain changes | Data changes | Presentation changes |
|---------|-----------------|---------------|------------------------|
| Event registrations (events-ms) | n/a (backend-only, no domain layer split in this microservice) | `RegistrationsService.create()` gains fail-fast age gate; `RegistrationsService.findByEvent()` gains `applyPrivacyMask()` step | n/a — no Flutter changes this phase |

No Flutter (`lib/`) changes. No new microservice, no new module, no new contracts.

## API contracts (rideglory-api changes)

No new endpoints, no request/response shape changes at the transport boundary (`GET /events/:eventId/registrations` keeps its existing shape; only field *values* change from real → sentinel depending on rules). No changes to `@rideglory/contracts`.

| Method | Path | Auth | Request body | Success | Errors (new) |
|--------|------|------|---------------|---------|--------------|
| POST | `/events/:eventId/registrations` (unchanged path, via `createRegistration` RPC) | Firebase ID token (existing) | unchanged | unchanged | **NEW:** `422 UNDERAGE_RIDER` when rider's computed age < 18 |
| GET | `/events/:eventId/registrations` (via `getRegistrationsByEvent` RPC) | Firebase ID token (existing) | unchanged | same shape, some fields now return sentinel strings `"__NOT_SHARED__"` / `"••••"` instead of real values, per the masking table below | unchanged |

## New models and DTOs

None. No new files in `rideglory-contracts`. New test files only (see Change map).

## Environment variables

None.

## Change map (master list — Build touches only what's here)

| File | Action | Reason | Risk |
|------|--------|--------|------|
| `events-ms/src/registrations/registrations.service.ts` | modify | Add `ensureRiderIsAdult()` fail-fast call in `create()`; capture `event` in `findByEvent()` and apply `applyPrivacyMask()` per-registration after `enrichRegistrationsWithVehicle`; add both private methods | high |
| `events-ms/src/registrations/registrations.service.age-validation.spec.ts` | create | Unit tests for the 2 boundary criteria (17y364d rejected, exactly-18-today accepted) plus 2 more edge cases per PRD (4 total) | low |
| `events-ms/src/registrations/registrations.service.privacy-mask.spec.ts` | create | Unit tests for the 5 masking combinations (medical info, emergency contact, phone, PII/SOS) per criteria 3-9 | low |

No changes to `events-ms/prisma/schema.prisma`, `events-ms/prisma/migrations/`, `events-ms/src/registrations/registrations.controller.ts`, `events-ms/src/registrations/registrations.module.ts`, `rideglory-contracts/**`, or any Flutter file.

## Implementation detail — `ensureRiderIsAdult` (2a)

Insert **after** `ensureUserHasNoActiveRegistration()` and **before** `ensureVehicleIdForNonOwner()`, preserving the existing validation order (guardrail, verbatim from PRD §6):

```ts
private ensureRiderIsAdult(birthDate: Date): void {
  const today = new Date();
  let age = today.getFullYear() - birthDate.getFullYear();
  const monthDiff = today.getMonth() - birthDate.getMonth();
  if (monthDiff < 0 || (monthDiff === 0 && today.getDate() < birthDate.getDate())) {
    age--;
  }
  if (age < 18) {
    throw new RpcException({
      status: HttpStatus.UNPROCESSABLE_ENTITY, // 422
      message: 'UNDERAGE_RIDER',
    });
  }
}
```

Call site in `create()`:
```ts
await this.ensureUserHasNoActiveRegistration(eventId, userId);
this.ensureRiderIsAdult(data.birthDate);
this.ensureVehicleIdForNonOwner(data.vehicleId, event.ownerId, userId);
```

`data.birthDate` is already a real `Date` object at this point — `CreateRegistrationDto.birthDate` is decorated `@Type(() => Date) @IsDate()` in `rideglory-contracts/src/events/dto/create-registration.dto.ts`, so `class-transformer` has already coerced it before the RPC payload reaches `RegistrationsService.create()`. No parsing needed.

`HttpStatus.UNPROCESSABLE_ENTITY` = 422, matches PRD criterion exactly. Message field carries `'UNDERAGE_RIDER'` (not a `code` field) — matches the existing `RpcException` pattern used throughout this file (e.g. `OWNER_CANNOT_REGISTER_MANUALLY`, `VEHICLE_REQUIRED`).

**Not** in `update()` — PRD scope (§6 guardrails) only requires the gate in `create()`.

## Implementation detail — `applyPrivacyMask` (2b)

Modify `findByEvent()`:
```ts
async findByEvent(eventId: string) {
  const event = await this.ensureEventExists(eventId);

  const registrations = await this.eventRegistration.findMany({
    where: { eventId },
    orderBy: { createdAt: 'asc' },
  });

  const enriched = await this.enrichRegistrationsWithVehicle(registrations);
  return enriched.map((registration) => this.applyPrivacyMask(registration, event));
}
```

Note the `event` variable is now captured from `ensureEventExists()`'s return value (currently discarded) — this is the only signature-preserving change to that private helper's call site.

New private method — **`bloodType` typed as `string` in signature, not `BloodType`** (guardrail R1, explicit in PRD §3 and §6):

```ts
private applyPrivacyMask<
  T extends {
    shareMedicalInfo: boolean;
    allowOrganizerContact: boolean;
    eps: string;
    medicalInsurance: string | null;
    bloodType: string; // widened from Prisma's BloodType enum — sentinel is a plain string
    emergencyContactName: string;
    emergencyContactPhone: string;
    phone: string;
    identificationNumber: string;
    email: string;
    residenceCity: string;
  },
>(
  registration: T,
  event: { state: EventState; sosTriggeredAt: Date | null },
): T {
  const medicalVisible =
    event.state === EventState.IN_PROGRESS && registration.shareMedicalInfo === true;
  const emergencyVisible = event.state === EventState.IN_PROGRESS;
  const contactVisible = registration.allowOrganizerContact === true;
  const sosVisible = event.sosTriggeredAt !== null;

  return {
    ...registration,
    eps: medicalVisible ? registration.eps : '__NOT_SHARED__',
    medicalInsurance: medicalVisible ? registration.medicalInsurance : '__NOT_SHARED__',
    bloodType: medicalVisible ? registration.bloodType : '__NOT_SHARED__',
    emergencyContactName: emergencyVisible ? registration.emergencyContactName : '••••',
    emergencyContactPhone: emergencyVisible ? registration.emergencyContactPhone : '••••',
    phone: contactVisible ? registration.phone : '••••',
    identificationNumber: sosVisible ? registration.identificationNumber : '••••',
    email: sosVisible ? registration.email : '••••',
    residenceCity: sosVisible ? registration.residenceCity : '••••',
  };
}
```

Because `T`'s `bloodType` constraint is declared as `string` (not the Prisma `BloodType` enum) in the generic bound, the object returned by `enrichRegistrationsWithVehicle` (which carries `bloodType: $Enums.BloodType`, a string-backed enum) still satisfies the constraint structurally — enums declared as string unions are assignable to `string`. This satisfies R1 without needing a cast.

`EventState` import: use the existing generated Prisma enum — `import { PrismaClient, EventState } from '../generated/prisma';` (the file currently imports `PrismaClient` from that module only; add `EventState` to the same import). Do **not** import `EventState` from `@rideglory/contracts` — that's a parallel, string-value-compatible but structurally distinct enum used by the Flutter-facing DTOs; mixing the two invites drift.

`medicalInsurance` is `string | null` in Prisma — when masked it becomes the literal string `'__NOT_SHARED__'`, never `null`, satisfying the guardrail explicitly (PRD §6: "medicalInsurance ... debe pasar el centinela ... nunca null").

## Masking rules table (verbatim reference, PRD §5)

| Campo(s) | Condición para mostrar valor real | Centinela si ofuscado |
|---|---|---|
| `eps`, `medicalInsurance`, `bloodType` | `event.state === 'IN_PROGRESS' && registration.shareMedicalInfo === true` | `"__NOT_SHARED__"` |
| `emergencyContactName`, `emergencyContactPhone` | `event.state === 'IN_PROGRESS'` | `"••••"` |
| `phone` | `registration.allowOrganizerContact === true` | `"••••"` |
| `identificationNumber`, `email`, `residenceCity` | `event.sosTriggeredAt !== null` | `"••••"` |

## Test file guidance

`registrations.service.age-validation.spec.ts` (4 cases, per PRD criteria 1-2 plus 2 more edge cases suggested by the boundary): 17y364d → throws `RpcException` with `status: 422`, `message: 'UNDERAGE_RIDER'`; exactly 18 today → no throw; comfortably over 18 → no throw; comfortably under 18 → throws. Must mock `usersService` and `vehiclesService` as **two separate** `ClientProxy` mocks (matches the existing pattern already present in `registrations.service.spec.ts`, lines ~50-60 — do not copy the single-mock pattern from `events.service.spec.ts`, per guardrail R3).

`registrations.service.privacy-mask.spec.ts` (5 combinations, per PRD criteria 3-9): SCHEDULED event → medical fields sentinel regardless of `shareMedicalInfo`; IN_PROGRESS + `shareMedicalInfo=true` → medical fields real; IN_PROGRESS + `shareMedicalInfo=false` → medical fields sentinel; `allowOrganizerContact` true/false → phone real/sentinel; `sosTriggeredAt` null/non-null → PII fields sentinel/real. Assert `vehicleSummary` survives (guardrail: mask applied after `enrichRegistrationsWithVehicle`, not before). Call `findByEvent()` directly (not `applyPrivacyMask()` in isolation) for at least one case, to prove the wiring, since `applyPrivacyMask` is private.

## Data/migraciones

None. `docs/exec-runs/legal-privacidad-edad-fase2/analysis/MIGRATION_PLAN.md` not created — nothing to migrate.

## Env

None. `docs/exec-runs/legal-privacidad-edad-fase2/analysis/ENV_DELTA.md` not created — no env changes.

## Risks and open questions

- **R1 (bloodType typing)** — mitigated by the explicit `string`-bound generic signature above; verify with `npx tsc --noEmit` after implementation.
- **R3 (test mock pattern)** — mitigated by reusing the two-`ClientProxy`-mock pattern already present in `registrations.service.spec.ts`.
- **R5 (vehicleSummary loss)** — mitigated by calling `applyPrivacyMask` strictly after `enrichRegistrationsWithVehicle` in `findByEvent()`; spec must assert `vehicleSummary` is preserved.
- **R6 (Fase 1 fields)** — resolved: all 4 fields confirmed present in `schema.prisma`, no gate blocking.
- **Contract drift (new finding, not in original PRD risk list)** — `EventRegistrationDto.bloodType` in `rideglory-contracts` is still strictly typed `BloodType`, not widened as the PRD claimed. Non-blocking for this phase (unused as a type annotation in the actual code paths); flagged for the team to fix before Flutter Fase 3-7 consumes this contract, otherwise Flutter's generated DTO will not accept the sentinel string.
- No open questions blocking implementation.

## Orden de implementación

1. Confirm pre-flight gates (done here — both satisfied, no migration).
2. Implement `ensureRiderIsAdult()` in `registrations.service.ts`; wire into `create()` at the specified location (2a).
3. Write `registrations.service.age-validation.spec.ts` (4 cases); run `npx jest registrations.service.age-validation`.
4. Implement `applyPrivacyMask()` in `registrations.service.ts`; wire into `findByEvent()` after `enrichRegistrationsWithVehicle` (2b).
5. Write `registrations.service.privacy-mask.spec.ts` (5 combinations); run `npx jest registrations.service.privacy-mask`.
6. Run `npx tsc --noEmit` in `events-ms` — zero errors required (criterion 10).
7. Run the full `events-ms` jest suite once more to confirm no regression in `registrations.service.spec.ts` (existing tests for `create()`/`update()` order must still pass unchanged).

## Superficie de regresión

- `RegistrationsService.create()` — validation order change; any existing test asserting the exact sequence of calls (`ensureUserHasNoActiveRegistration` → `ensureVehicleIdForNonOwner`) in `registrations.service.spec.ts` must still pass since the new call sits between them without altering their behavior when age ≥ 18.
- `RegistrationsService.findByEvent()` — response field *values* change for `eps`, `medicalInsurance`, `bloodType`, `emergencyContactName`, `emergencyContactPhone`, `phone`, `identificationNumber`, `email`, `residenceCity` under specific conditions. Any existing test/consumer asserting real values unconditionally in `findByEvent()` will break — expected and in-scope per PRD; no known existing test currently asserts this (single existing spec targets `create()`).
- `findMyRegistrationForEvent()` and `findMyRegistrations()` — untouched, must continue returning unmasked data (criterion 11).
- `api-gateway/src/registrations/registrations.controller.ts` — untouched (pass-through), no risk.
- `rideglory-contracts` — untouched.

## Fuera de alcance

- Flutter (`lib/`) — Fases 3-7, not this phase.
- Ofuscación en `findMyRegistrationForEvent` / `findMyRegistrations` — explicitly excluded (PRD §3, guardrail §6).
- Validación de `riskAcceptedAt` en `create()` — closed in Fase 1 (422 `RISK_NOT_ACCEPTED`), not touched here.
- Validación de `organizerAcceptedResponsibilityAt` al publicar evento — Fase 1/5, not touched here.
- Cambios en `rideglory-contracts` — none needed; the `bloodType` typing drift noted above is a pre-existing gap from Fase 1, not something to fix in this phase.
- `schema.prisma` / migrations — no change, pre-flight gate satisfied without contingency.

## Next agent needs to know

- Backend (rideglory-api): implement exactly the two methods above in `events-ms/src/registrations/registrations.service.ts`; write the two spec files; run `npx tsc --noEmit` and the two `npx jest` commands before declaring done. No other files change.
- Flutter dev (frontend): **stand down** — this phase has zero Flutter changes.
- QA: primary verification is the 12 acceptance criteria in the PRD, all covered by the two new unit test files plus `npx tsc --noEmit`. No Patrol/e2e needed (backend-only, no UI).

## Change log
- 2026-07-01T04:19:30Z: Architect phase complete. Pre-flight gates confirmed satisfied (no migration). Corrected PRD §4 claim about `rideglory-contracts` bloodType typing (not actually closed, but non-blocking). Full implementation detail for `ensureRiderIsAdult()` and `applyPrivacyMask()` specified, including exact call sites, generic typing strategy for R1, and EventState import source. Change map: 1 modify + 2 create, all within `events-ms/src/registrations/`.
