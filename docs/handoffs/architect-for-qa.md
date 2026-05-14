> Slim handoff — read this before docs/handoffs/architect.md

# Architect → QA — Iteration 2

Iter-2 ships two new features (SOAT, notifications) full-stack. Quality gate = unit + cubit + widget coverage for new code, `dart analyze` zero violations, `flutter test` zero new failures, 6 notification types verified on device.

## Test commands

```bash
# Pre-flight — regenerate codegen FIRST (new SOAT + Notification DTOs/services)
dart run build_runner clean
dart run build_runner build --delete-conflicting-outputs

# Static analysis — zero errors / zero warnings (no new violations)
dart analyze

# Unit + widget + cubit tests
flutter test

# Single file (debugging)
flutter test test/<path>_test.dart
```

After `build_runner` the 4 pre-existing failures (`user_service.g.dart` missing `getUserById`, `event_service.g.dart` signature mismatch) should clear. If they persist, flag — backend DTO drift.

## Test targets (T-2-12)

### Unit — `SoatModel.status` 4-state boundary logic
| Case | Input | Expected |
|------|-------|----------|
| Vigente | `expiryDate` = now + 31d | `SoatStatus.valid` |
| Boundary >30 | `expiryDate` = now + 30d | `SoatStatus.expiringSoon` (`<= 30` rule) |
| Por vencer | `expiryDate` = now + 7d | `SoatStatus.expiringSoon` |
| Boundary day-of | `expiryDate` = today | `SoatStatus.expiringSoon` (not past) |
| Vencido | `expiryDate` = now - 1d | `SoatStatus.expired` |
| Sin SOAT | no record / null model | `SoatStatus.noSoat` |

### Cubit (BLoC tests, mocktail) — min 5 cases each
- `SoatCubit`: initial → loading → data; loading → empty (no SOAT, 204); loading → error; save success → data; save failure → error.
- `NotificationsCubit`: initial load (loading → data); empty (loading → empty); error (loading → error); `loadMore()` appends page using `nextCursor`, `isLoadingMore` toggles; `markRead(id)` flips `isRead` + decrements `unreadCount`; `markAllRead()` zeroes `unreadCount`.

### Widget — 4 cases each (loading skeleton, data render, empty, error banner)
`SoatUploadPage`, `SoatManualFormPage`, `NotificationCenterPage`.
- `SoatManualFormPage`: also assert expiry-date-required inline validation.
- `NotificationCenterPage`: empty state shows "Aún no tienes notificaciones"; unread shows orange dot.

### Story 2.9 — ManageAttendeesPage
No new cubit tests (no new state management). Verify: no hardcoded color literals, `AppButton`/`AppDialog` usage, loading/empty/error states correct per frame `dUc9h`.

## Acceptance criteria traceability

| Story | Criterion | Verification |
|-------|-----------|--------------|
| US-2-1 | document saved, badge → Vigente/Por vencer; upload errors as Spanish snackbars | widget test + manual upload |
| US-2-2 | expiry required + validated; 4-state badge correct on save | unit (`SoatModel.status`) + widget validation test |
| US-2-3 | 4 states from `expiryDate` vs today; badge tappable → SOAT flow | unit boundary table + widget tap test |
| US-2-4 | SOAT push 30d/7d/day-of with vehicle name; appear in center | on-device cron verification |
| US-2-5 | organizer push on new registration; bell badge increments | on-device + `NotificationsCubit` unreadCount test |
| US-2-6 | push on approve/reject within 30s; "My Registrations" reflects status | on-device |
| US-2-7 | cursor pagination `{ data, nextCursor }`; `PATCH /:id/read`, `/read-all`; bell badge from backend; empty state | `NotificationsCubit` tests + widget test |
| US-2-8 | backend endpoints + `notifications` table + `fcmToken` | backend integration (curl GET/PATCH) |
| US-2-9 | design system components, no hardcoded colors, states correct | PR review + widget render |
| US-2-10 | full coverage; `dart analyze` 0; `flutter test` 0 new fails | this whole gate |

## 6 notification types on device/emulator (Firebase project required)

SOAT 30d, SOAT 7d, SOAT day-of, new registration (organizer), registration approved, registration rejected. Requires physical device or emulator with FCM-configured Firebase project.

## Architecture quality gates QA enforces in PR review

- No `BuildContext` in `lib/features/soat/data/` or `lib/features/notifications/data/`.
- No offset/limit pagination anywhere — grep service files for `cursor` only.
- FCM background handler is a top-level function with `@pragma('vm:entry-point')` and calls `configureDependencies()`.
- `DocumentSlotPill` callers pass localized `stateLabel` (no reliance on molecule fallback strings).
- No hardcoded `Color(0x...)` / non-exempt `Colors.<named>` in new feature files.
- New cubits/services/repos registered via annotations; `injection.config.dart` regenerated and committed.

## Scope reduction rule

If US-2-7 backend read-persistence is at risk near iteration end, the unread badge may fall back to a local `SharedPreferences` cache as a provisional measure — but the backend endpoints (US-2-8) must be complete regardless.

> Full detail: docs/handoffs/architect.md
