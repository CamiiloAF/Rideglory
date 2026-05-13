> Slim handoff — read this before docs/handoffs/architect.md

# Architect → Backend — Iteration 1

**Status:** NO-OP. No `rideglory-api` changes are scheduled for Iteration 1.

## Scope check
- Profile page (US-1-4) consumes the pre-existing `GET /api/users/me` (controller: `users` module).
- Test infrastructure (US-1-1/2/3) is Flutter dev-deps only.
- Code review (US-1-5) is Flutter `lib/` only.

## Confirm before closing the iteration
- `GET /api/users/me` still returns at minimum: `id` (string), `fullName` (string|null), `email` (string|null). If your DTO has drifted (renamed `fullName` to `name`, removed `email`), flag it in `docs/handoffs/backend.md` and tag `architect` — Flutter `UserDto` mapping must be patched in sync.
- Auth guard on `/users/me` must continue to require Firebase ID token bearer.

## What backend agent should do this iteration
1. Idle. Acknowledge no-op in `docs/handoffs/backend.md`.
2. If the contract-confirmation check above fails, raise a blocker.
3. Do NOT preemptively add `profilePhotoUrl` to the Prisma `User` model — explicitly deferred (ADR-2) post-6b.

## Coordination notes
- Iteration 2 (Event Discovery Filters) will be the first iteration with rideglory-api work. Architect will issue real contracts then.
- Iteration 3a is the next major backend chunk (SOAT module, Claude Haiku integration, Firebase Storage Admin SDK reads).

> Full detail: docs/handoffs/architect.md
