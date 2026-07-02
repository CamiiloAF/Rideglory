> Slim handoff — read this before handoffs/architect.md

# Backend — legal-privacidad-edad-fase2

**Only file with logic changes:** `events-ms/src/registrations/registrations.service.ts`
**New test files:** `events-ms/src/registrations/registrations.service.age-validation.spec.ts`, `events-ms/src/registrations/registrations.service.privacy-mask.spec.ts`

**No migration.** `sosTriggeredAt` and all 4 Fase 1 fields (`shareMedicalInfo`, `allowOrganizerContact`, `riskAcceptedAt`, `riskAcceptanceVersion`) already exist in `schema.prisma` — confirmed by reading the file. Do not touch `schema.prisma` or `prisma/migrations/`.

**No contract changes.** Do not touch `rideglory-contracts`.

## 2a — Age gate in `create()`

Add private method `ensureRiderIsAdult(birthDate: Date): void` — computes age via year/month/day comparison (not just year subtraction), throws `RpcException({ status: HttpStatus.UNPROCESSABLE_ENTITY, message: 'UNDERAGE_RIDER' })` when age < 18. `HttpStatus.UNPROCESSABLE_ENTITY` = 422.

Call site — insert between the two existing calls, do not reorder anything else:
```ts
await this.ensureUserHasNoActiveRegistration(eventId, userId);
this.ensureRiderIsAdult(data.birthDate);
this.ensureVehicleIdForNonOwner(data.vehicleId, event.ownerId, userId);
```
`data.birthDate` is already a `Date` (class-transformer `@Type(() => Date)` on `CreateRegistrationDto`), no parsing needed. Not applied in `update()` — `create()` only.

## 2b — Privacy mask in `findByEvent()`

Capture `event` (currently discarded) and map after enrichment:
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

New private `applyPrivacyMask<T extends {...}>(registration: T, event: { state: EventState; sosTriggeredAt: Date | null }): T` — **`bloodType` must be constrained as `string` in the generic bound, not `BloodType`** (avoids TS error when assigning the sentinel; Prisma's string-backed enum is structurally assignable to `string`). Full method body with exact field list and masking rules table is in `handoffs/architect.md` under "Implementation detail — applyPrivacyMask (2b)". Follow it verbatim — the sentinel strings (`"__NOT_SHARED__"` vs `"••••"`) are exact-match tested per field group, do not swap them.

Import `EventState` from `../generated/prisma` (add to the existing `PrismaClient` import from that module) — do not import from `@rideglory/contracts`.

`medicalInsurance` masked value must be the string `'__NOT_SHARED__'`, never `null`.

## Test requirements

Mock **both** `usersService` and `vehiclesService` as separate `ClientProxy` mocks — copy the pattern already in `registrations.service.spec.ts` (lines ~50-60), do not use the single-mock pattern from `events.service.spec.ts`.

Privacy-mask spec must assert `vehicleSummary` survives masking (proves ordering: mask runs after `enrichRegistrationsWithVehicle`).

## Verification before done

```
cd events-ms
npx tsc --noEmit
npx jest registrations.service.age-validation registrations.service.privacy-mask
npx jest registrations.service   # full existing spec, no regression
```

> Full detail: handoffs/architect.md
