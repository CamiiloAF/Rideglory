# Backend Audit — remove-city-field

**Auditor:** Opus
**Date:** 2026-06-11T22:09:41Z
**Verdict:** APPROVED (score 92)

---

## Scope verified

Changes live in the `rideglory-api` super-repo submodules (not the Flutter repo working tree):
- `rideglory-contracts`: 3 DTOs
- `events-ms`: schema, seed, service, spec, migration
- `api-gateway`: gemini.service + 3 spec files

## Acceptance criteria

| AC | Result |
|----|--------|
| #2 schema.prisma no `Event.city` | PASS — column removed; `residenceCity` (EventRegistration model) correctly preserved |
| #3 contracts no `city` in events/ai | PASS — only `residenceCity` (registration) remains, unrelated field |
| #4 migration applied, tsc, tests | PASS — migration `20260611000000_remove_event_city` applied; `prisma migrate status` = up to date; `tsc --noEmit` clean in events-ms + api-gateway; events-ms **24/24**, api-gateway ai **37/37** green |
| #10 gemini.service no `city` in payload | PASS — `- Ciudad: ${...}` line removed from prompt; system-prompt context list updated; no `eventContext.city` reference remains |

## Verification performed

- `psql events -c '\d "Event"'` → no `city` column (confirmed).
- `npx tsc --noEmit` both services → exit 0.
- `npx jest` events-ms → 24/24; api-gateway `src/ai` → 37/37.
- Residual scan: no `Event.city` / `eventContext.city` anywhere. Remaining `city` hits are `residenceCity` (EventRegistration) and `places/colombia-cities.data.ts` (places autocomplete) — both legitimately unrelated.

## Notes / findings

- The "grep city returns empty" wording in AC#2/#3 is a naive guardrail that false-positives on `residenceCity`. Intent (Event.city) is fully satisfied; preserving `residenceCity` is correct per guardrails.
- Test strategy is sound for a pure removal: `city` removed from mock DTOs so they type-check against the new contracts; `tsc` passing is the guardrail that `city` can no longer be passed. TC-4/TC-5 (city filter tests) deleted as the feature no longer exists; TC-1/TC-2/TC-3 updated to match actual service behavior (`notIn ['DRAFT','IN_PROGRESS']`, `orderBy desc`) — these were pre-existing stale assertions, legitimately corrected.
- SQL: migration uses plain DDL `ALTER TABLE "Event" DROP COLUMN "city"` — no concatenation/injection. Prisma `where` clauses parameterized. No secrets/PII introduced.

## Non-blocking concern

- `pnpm-lock.yaml` in both `events-ms` and `api-gateway` shows additions of `pino`/`nestjs-pino`/`nestjs-cls`/`pino-http`/`uuid@14` — these belong to the concurrent **observability-sentry** effort, NOT to this change map. They are lockfile-only artifacts from the dirty working tree; this task added no runtime deps. The human must commit selectively (exclude these lockfile diffs from the remove-city-field commit). Does not block approval since no city-removal source touches them.
