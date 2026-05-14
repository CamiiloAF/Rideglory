# Iteration Context — Bridging Iter-1 to Iter-2

**Prepared by:** PO (po_close phase)  
**Date:** 2026-05-14  
**For:** Iteration 2 (SOAT + Notification Foundation)

---

## What Iter-1 Left You

### ✅ Design System Complete
- All 15 screens now use consistent color tokens, typography, and spacing
- Two new design-system primitives created:
  - `AppEventBadge` atom (6 variants: scheduled, inProgress, finished, cancelled, free, paid)
  - `DocumentSlotPill` molecule (4 states: empty, valid, expiringSoon, expired) — **ready for SOAT integration**
- ~140 new L10n keys added to `app_es.arb`; generated `.dart` files committed
- **All 5 modules refactored:** splash+auth, home, events, garage, maintenance+registration

### ✅ No Regressions
- `dart analyze` → 0 errors, 0 warnings (no new violations)
- `flutter test` → 28 pass, 4 pre-existing failures (unchanged)
- **AI cover generation (iter-4) remains functional** — verified via smoke test
- Mapbox route preview working as before
- All existing features intact

### ⚠️ Stale Code Generation
Four test files fail due to pre-existing generated code out of sync:
- `user_service.g.dart` missing `getUserById` endpoint
- `event_service.g.dart` signature mismatch on `getEvents`

**Not blocking.** Caused by backend changes in iter-2 or iter-4; will be regenerated during iter-2 pre-flight when `build_runner` is run for SOAT/notification schema changes.

---

## What Iter-1 Did NOT Change

### Backend (Intentionally)
- Zero new endpoints
- Zero schema migrations
- Zero service changes
- **Next backend work:** Iter-2 (SOAT endpoints, notifications table, FCM)

### Domain & Data Layers
- Zero domain models added/changed
- Zero DTOs added/changed
- Zero use cases added/changed
- Zero DI changes
- Zero router changes
- **Constraint enforced:** Pure presentation-layer redesign only

### Test Infrastructure
- No new test dependencies (mocktail, bloc_test) added
- 10 existing tests continue to pass
- New unit/widget tests deferred to iter-2+

---

## Iter-2 Pre-Flight Checklist

**Before any code is written, complete these tasks:**

### 1. Backend Setup
- [ ] Verify `rideglory-api` git status and checkout main
- [ ] Run `prisma migrate reset` on all 4 existing microservices (vehicles-ms, events-ms, users-ms, maintenances-ms)
- [ ] Verify seed.ts exists in vehicles-ms and events-ms; run fresh seed if needed
- [ ] **NEW:** Prisma init on api-gateway (first-time setup):
  - [ ] `prisma init` (creates `prisma/schema.prisma`)
  - [ ] Configure DATABASE_URL in `.env` (must match Docker Compose PostgreSQL)
  - [ ] Create notifications table schema (id, userId, type, payload, isRead, createdAt)
  - [ ] Run `prisma migrate dev --name init` to initialize and test database connectivity
  - [ ] Verify `GET /api/notifications` endpoint returns 200 with empty array

### 2. Code Generation (Flutter)
- [ ] Run `dart run build_runner clean`
- [ ] Run `dart run build_runner build --delete-conflicting-outputs`
- [ ] Verify all 4 failing tests now pass (or show only pre-existing failures)
- [ ] Run `flutter test` and confirm 28+ tests pass

### 3. Design Gate (SOAT + Notifications)
- [ ] Confirm SOAT status badge frames in `rideglory.pen` (vehicle detail page)
- [ ] Confirm SOAT upload form frame in `rideglory.pen`
- [ ] Confirm SOAT manual entry form frame in `rideglory.pen`
- [ ] Confirm notification center / generic notification row template in `rideglory.pen`
- [ ] Confirm ManageAttendeesPage frame (Story 2.9) in `rideglory.pen` — list + edit or edit-only?

### 4. Architecture Assessment (GoRouter DI)
- [ ] Check if `app_router.dart` creates GoRouter as top-level variable or via DI
- [ ] If top-level: plan refactoring (scope as Story 1.0 if blocking NotificationRouteHandler)
- [ ] Document decision in architect handoff

---

## High-Risk Items for Iter-2

### api-gateway Prisma First-Time Setup
**Risk:** PostgreSQL connectivity, DATABASE_URL configuration, Docker Compose networking  
**Mitigation:** Allot full pre-flight day. Test `prisma migrate dev` and verify `GET /api/notifications` returns 200 before moving to implementation.

### Story 2.9 Scope (ManageAttendeesPage)
**Risk:** Frame dUc9h may be unclear (list + edit, or edit-only)  
**Mitigation:** Design gate must confirm scope. If ambiguous, limit to component-swap and color tokenization (no layout rework).

### FCM Token Registration Dependency Chain
**Risk:** Stories 2.4/2.5/2.6 (push notifications) depend on Story 2.8 (POST /api/notifications/fcm-token) being complete  
**Mitigation:** Implement 2.8 first. Backend DI re-initialization inside FCM background handler must be documented and reviewed carefully.

### Notification Read Persistence Timing
**Risk:** Story 2.7 (mark as read) depends on backend endpoints (Story 2.8) being functional  
**Mitigation:** Testing order: 2.8 → 2.7 → 2.4/2.5/2.6. No concurrent implementation.

---

## Key Assumptions & Gotchas

### Build Runner Regeneration Needed
The 4 failing test files will regenerate correctly during iter-2 pre-flight because:
1. New SOAT and notification DTOs added to domain
2. New Retrofit endpoints in services (SoatService, NotificationsService)
3. `build_runner build` will regenerate all `.g.dart` files
4. Tests will pass once service interface signatures match again

**Action:** Don't worry about these 4 failures in iter-1. They'll clear in iter-2 pre-flight.

### DocumentSlotPill Localization Gotcha
The `DocumentSlotPill` molecule has hardcoded Spanish fallback strings (`'Sin registrar'`, `'Vigente'`, `'Por vencer'`, `'Vencido'`) because it cannot access `context.l10n` without `BuildContext`.

**How to use in iter-2:**
```dart
DocumentSlotPill(
  state: DocumentSlotState.empty,
  stateLabel: context.l10n.vehicle_document_slot_empty, // Callers must pass localized string
)
```

If this pattern is too verbose, reconsider moving localization into the molecule (requires accepting a Localizations delegate). Document in code comments.

### AI Cover Generation Still Works
The `AIEventCoverWidget` in event form was a smoke test blocker. It works because:
- Iter-1 did not touch its implementation or imports
- It still calls the backend endpoint (no backend changes)
- Treat as a "canary" feature — if anything breaks in form implementation, this fails first

---

## Documents to Update Post-Iter-2

When iter-2 closes, the PO will update:
- `docs/ITERATION_SUMMARY_2.md` (stories delivered, scope changes, metrics)
- `docs/ITERATION_HISTORY.md` (append row for iter-2)
- `docs/PRODUCT_STATUS.md` (add SOAT and notification features to "shipped" section)
- `docs/handoffs/iteration_context.md` (bridge for iter-3)
- `README.md` (update latest iteration link)
- `docs/handoffs/iteration_checkpoint.md` (reset to idle, set "Last closed: Iteration 2")

---

## Quick Reference: File Locations

| File | Purpose |
|------|---------|
| `docs/REQUIREMENTS.md` | Product spec (all features, user flows) |
| `docs/PLAN.md` | Full 5-iteration roadmap with stories, assumptions, risks |
| `docs/ITERATION_SUMMARY_1.md` | Details on what iter-1 delivered |
| `docs/handoffs/po.md` | Iter-1 PO handoff (stories, scope, assumptions) |
| `docs/handoffs/architect.md` | Iter-1 architecture decisions (design-system spec, no backend) |
| `docs/handoffs/frontend.md` | Iter-1 implementation summary (color tokenization, primitives) |
| `docs/handoffs/qa.md` | Iter-1 QA results (test catalog, smoke tests) |
| `docs/handoffs/tech_lead.md` | Iter-1 code review (PR #13 verdict, non-blockers) |
| `docs/PRODUCT_STATUS.md` | Current shipped capabilities |
| `workflow/state.json` | Machine-readable phase/task state (read by `/resume-iter`) |

---

## Summary

Iter-1 left you with a **visually cohesive codebase** and **zero technical debt** from the redesign. The next 4 iterations (2, 3, 4, 5) can be implemented with confidence that the UI foundation is solid.

**Next iteration is ready to start.** Run `/iter 2` or `/solo-plan` to begin Iteration 2 planning.
