# Iteration Context — Bridging Iter-3 to Iter-4

**Prepared by:** PO (po_close phase)  
**Date:** 2026-05-15T07:30:00Z  
**For:** Iteration 4 (Social follow system + profile completion + deep link domain provisioning)

---

## What Iter-3 Left You

### ✅ Complete Real-Time Tracking & Emergency System
- **Mapbox SDK migration** (Story 3.0): google_maps_flutter + geocoding fully removed; mapbox_maps_flutter ^2.2.0 deployed
- **SOS emergency system** (Stories 3.1–3.2): Red button → confirmation → broadcast to all riders + FCM push; Llamar/Localizar actions with phone check
- **Organizer ride controls** (Stories 3.3–3.4): Start/end ride buttons; auto-close tracking for all riders on finish
- **Background GPS** (Story 3.5): Android foreground service (non-dismissible notification) + iOS system location indicator
- **Maintenance & event reminders** (Stories 3.6–3.7): 30d maintenance + 24h event cron jobs (America/Bogota timezone)
- **SOAT badge** (Story 3.10): 4-state display on Home Dashboard (Sin SOAT, Vigente, Por vencer, Vencido)

### ✅ Code Quality & Architecture
- `dart analyze` → 0 errors, 0 warnings (3 Mapbox SDK info hints acceptable)
- `flutter test` → 47 pass, 1 pre-existing failure (unrelated to iter-3)
- **Clean Architecture enforced:** LiveTrackingCubit depends on domain TrackingRepository only; no EventService/Dio/WsClient imports in presentation
- **One widget per file enforced:** sos_banner_action.dart extracted; home_garage_card.dart uses sibling files
- **Localization complete:** ~30 new l10n keys in app_es.arb; no hardcoded Spanish strings in new code

### ✅ Backend Ready for Social Features
- All tracking endpoints deployed: POST start/end, GET route (GeoJSON), GET geocode
- Event participant lookup patterns proven (for SOS multicast broadcast)
- Notification table mature: ready to add FOLLOW type
- WS infrastructure stable: patterns for sosAlerts + eventEnded can be reused for follow observability

### ⚠️ PR #15 Status
- **Tech lead review:** APPROVED (2026-05-15T07:00:00Z)
- **Merge status:** Pending human action (not yet merged to main)
- **Critical:** Must merge before /iter 4 begins to avoid merge conflicts with follow system

---

## What Iter-3 Deferred (Ready for Iter-4)

### T-3-9 (Backlog) — Route Adherence Features
- **Route GeoJSON rendering:** GeoJsonSource + LineLayer on tracking map (not yet implemented)
- **Route adherence chip:** "En ruta ✓" / "Fuera de ruta ⚠" with 200m Haversine check (depends on T-3-9)
- **Candidate for iter-4 if time permits** after follow system; otherwise iter-4+ slot

### Post-MVP Deferred Items
- SOS sender cancel / dismiss (organizer dismiss only, post-MVP)
- Km-based maintenance reminders (requires odometer tracking, not defined in PRD)
- Notification tap routing (scheduled for iter-1, deep links phase)

---

## Iter-4 Pre-Flight Checklist

**Before any code is written, complete these tasks:**

### 1. Verify PR #15 Merge
- [ ] Check GitHub: is PR #15 merged to main?
- [ ] If NOT merged: flag to orchestrator; do not start iter-4 code until merged (avoid conflicts with follow system)
- [ ] If merged: pull main and verify Mapbox integration is stable

### 2. DevOps Post-Merge Actions
- [ ] Update CocoaPods cache key in GitHub Actions (Mapbox binary framework ~200MB) — must be done immediately after merge

### 3. Design Gate (Profile + Follow System)
- [ ] Confirm FollowersListPage frame in `rideglory.pen` (with quick-follow button, loading state, empty state)
- [ ] Confirm FollowingListPage frame in `rideglory.pen` (same states)
- [ ] Confirm profile frame (A7qDd) final design in `rideglory.pen` (bio, city, follower counts, public vehicles, organized events)
- [ ] Confirm follow button states in frame (default, in-flight, following)

### 4. Backend Setup (Follow System)
- [ ] Verify `rideglory-api` checkout main (post-iter-3 merge)
- [ ] Follow entity schema ready: followerId, followingId, createdAt, composite unique index (users-ms Prisma)
- [ ] Verify endpoints ready: POST /users/:userId/follow, DELETE /users/:userId/follow, GET /users/:userId/followers, GET /users/:userId/following
- [ ] Verify _count.followers and _count.following available in user profile response

### 5. GoRouter DI Assessment (Blocker for Iter-1)
- [ ] Check if `app_router.dart` creates GoRouter as top-level variable or via DI
- [ ] **If top-level:** Create refactoring task (Story 1.0 pre-flight for iter-1); document in architect handoff
- [ ] **If already in GetIt:** Document confirmation in architect handoff (no iter-1 blocker)

### 6. Deep Link Domain Provisioning (Hard Blocker for Iter-1)
- [ ] Provision custom domain with valid TLS certificate
- [ ] Create `.well-known/assetlinks.json` for Android App Links (exact format: SHA256 cert fingerprint + package name)
- [ ] Create `.well-known/apple-app-site-association` for iOS Universal Links (team ID + bundle ID)
- [ ] Deploy both files to custom domain; verify with curl that both return 200
- [ ] Test on real device: Universal Link cold-start (iOS) and App Link cold-start (Android)
- [ ] **Critical:** This must be done before iter-1 closes (deep links phase cannot start without verified domain)

---

## High-Risk Items for Iter-4

### Follow State Optimistic Update (Exception to ResultState<T>)
**Risk:** FollowCubit uses @freezed FollowState { isFollowing, followerCount, isLoading, error } instead of ResultState<T>  
**Mitigation:** Document as intentional architecture exception. Code review must verify: (1) optimistic update reverts visually on error, (2) follower count matches backend after fetch, (3) no race conditions on fast double-tap.

### FollowCubit Factory DI Pattern
**Risk:** FollowCubit is registered as factory (not @singleton) — one instance per userId; unusual pattern  
**Mitigation:** Document in DI module with comment explaining why (per-user state isolation). Code review must verify factory is registered correctly and not cached globally.

### GoRouter DI Refactoring (Potential Blocker for Iter-1)
**Risk:** If app_router.dart creates GoRouter as top-level variable, NotificationRouteHandler (iter-1) cannot inject it  
**Mitigation:** Assess in iter-4 pre-flight. If refactoring needed, scope as Story 1.0 pre-flight (do not defer to iter-1 implementation phase).

### Deep Link Domain TLS + HTTPS
**Risk:** assetlinks.json or apple-app-site-association unreachable, invalid TLS, or incorrect format  
**Mitigation:** Curl both endpoints before iter-4 closes. Test cold-start on physical device (release build, not debug). App Store / Play Store review will reject if links don't work.

---

## Key Assumptions & Gotchas

### Follow Button Loading State Visuals
The follow button must show loading state during the API call and revert visually on failure. Spec in design frame.

**Pattern:**
```dart
// Optimistic: isFollowing = true immediately
// During request: isLoading = true (show spinner)
// On success: update followerCount from backend
// On failure: isFollowing reverts, show snackbar error
```

### PublicVehicleDto vs. VehicleDto
Must be a separate class, NOT VehicleDto with null fields. Clean Architecture principle: domain model must not carry null fields representing hidden data.

```dart
// ❌ WRONG
class PublicVehicleDto extends VehicleDto { }

// ✅ CORRECT
class PublicVehicleDto {
  final String id;
  final String make;
  final String model;
  // No licensePlate, no insurance fields
}
```

### Follower Notification Type
Must be distinct from other notification types. Add `FOLLOWER_NOTIFICATION` or `NEW_FOLLOWER` to NotificationType enum; dispatch from api-gateway post-follow; mark reminderSentAt once sent.

### Pagination Offset vs. Cursor
Use offset/limit for followers/following lists (simpler than cursor pagination). Example: `GET /api/users/:userId/followers?page=1&limit=20`.

---

## Documents to Update Post-Iter-4

When iter-4 closes, the PO will update:
- `docs/ITERATION_SUMMARY_4.md` (stories delivered, follow system metrics)
- `docs/ITERATION_HISTORY.md` (append row for iter-4)
- `docs/PRODUCT_STATUS.md` (add follow system and complete profiles to "shipped")
- `docs/handoffs/iteration_context.md` (bridge for iter-1 — note deep link domain is live)
- `README.md` (update latest iteration link)
- `docs/handoffs/iteration_checkpoint.md` (reset to idle, set "Last closed: Iteration 4")

---

## Quick Reference: Key Files (Updated for Iter-3 Context)

| File | Purpose |
|------|---------|
| `docs/REQUIREMENTS.md` | Product spec (all features, user flows) |
| `docs/PLAN.md` | Full 5-iteration roadmap (iter-3 now confirmed complete) |
| `docs/ITERATION_SUMMARY_1.md` | Details on iter-1 (UI/UX redesign) |
| `docs/ITERATION_SUMMARY_3.md` | Details on iter-3 (tracking + SOS + Mapbox migration) |
| `docs/handoffs/po.md` | Iter-3 PO handoff (final version) |
| `docs/handoffs/architect.md` | Iter-3 architecture decisions (Mapbox, tracking SOS, WS patterns) |
| `docs/handoffs/frontend.md` | Iter-3 implementation summary (SOS, organizer controls, background GPS) |
| `docs/handoffs/backend.md` | Iter-3 backend (tracking endpoints, cron jobs, SOS handler) |
| `docs/handoffs/qa.md` | Iter-3 QA results (test catalog, hard gates, BUG-3-1 resolved) |
| `docs/handoffs/tech_lead.md` | Iter-3 code review (PR #15 approved after 2 cycles) |
| `docs/PRODUCT_STATUS.md` | Current shipped capabilities (iter-3 tracking in review) |
| `workflow/state.json` | Machine-readable phase/task state (iteration 3 done) |

---

## Summary

Iter-3 left you with a **production-ready real-time tracking system** and **complete emergency infrastructure**. The Mapbox migration eliminates vendor lock-in; the SOS system is ready for field testing; background GPS is implementable on both platforms.

**Critical path forward:**
1. **Human merge of PR #15** (tech lead approved)
2. **CocoaPods cache update** in CI/CD (DevOps post-merge)
3. **Iter-4 pre-flight** confirms follow system design, GoRouter DI, deep link domain
4. **Iter-4 implementation** adds social layer and deep link infrastructure (blocker for iter-1)
5. **Iter-1 final phase** completes Apple Sign-In, App Links, notification routing

**Next iteration is ready to plan.** Run `/iter 4` or `/solo-plan` to begin Iteration 4 planning once PR #15 is merged.
