> Slim handoff — read this before handoffs/architect.md

# QA — legal-privacidad-edad-fase2

Backend-only phase, no Flutter/UI changes, no Patrol e2e needed.

## Commands
```
cd events-ms
npx tsc --noEmit
npx jest registrations.service.age-validation
npx jest registrations.service.privacy-mask
npx jest registrations.service   # regression check on existing spec
```

## Acceptance criteria traceability (PRD §5, 12 total)

| # | Criterion | Covered by |
|---|-----------|-----------|
| 1 | 17y364d → `422 UNDERAGE_RIDER` | `registrations.service.age-validation.spec.ts` |
| 2 | Exactly 18 today → no throw | `registrations.service.age-validation.spec.ts` |
| 3 | SCHEDULED event → medical fields sentinel regardless of `shareMedicalInfo` | `registrations.service.privacy-mask.spec.ts` |
| 4 | IN_PROGRESS + `shareMedicalInfo=true` → medical fields real | `registrations.service.privacy-mask.spec.ts` |
| 5 | IN_PROGRESS + `shareMedicalInfo=false` → medical fields sentinel | `registrations.service.privacy-mask.spec.ts` |
| 6 | `allowOrganizerContact=false` → `phone = "••••"` | `registrations.service.privacy-mask.spec.ts` |
| 7 | `allowOrganizerContact=true` → `phone` real | `registrations.service.privacy-mask.spec.ts` |
| 8 | `sosTriggeredAt = null` → PII fields `"••••"` | `registrations.service.privacy-mask.spec.ts` |
| 9 | `sosTriggeredAt != null` → PII fields real | `registrations.service.privacy-mask.spec.ts` |
| 10 | `bloodType` never causes a TS error when `"__NOT_SHARED__"` | `npx tsc --noEmit` |
| 11 | `GET .../registrations/me` NOT masked | manual/inline check — `findMyRegistrationForEvent` untouched, no mask applied; assert by reading the diff (no test file required per PRD scope, but flag if `applyPrivacyMask` is accidentally wired there) |
| 12 | All new unit tests pass, 0 failures | `npx jest registrations.service.age-validation registrations.service.privacy-mask` |

## Regression watch
- `registrations.service.spec.ts` (existing) — `create()`/`update()` validation order must be unchanged aside from the new age gate insertion; must still pass.
- `findMyRegistrationForEvent`/`findMyRegistrations` must keep returning unmasked, real values — no test currently exists for this; consider a quick assertion that these two methods never call `applyPrivacyMask`.

> Full detail: handoffs/architect.md
