> Slim handoff — read this before docs/handoffs/architect.md

# Architect → QA — Iteration 3

**Hard gate:** widget test for `route_map_preview.dart` must be written and passing BEFORE Story 3.0 PR opens. No exceptions.

---

## Test commands

```bash
# Static analysis (must be zero errors/warnings after every PR)
dart analyze

# All tests
flutter test

# Single file
flutter test test/<path>_test.dart

# Code generation (run before tests if DTOs or services changed)
dart run build_runner build --delete-conflicting-outputs
```

---

## T-3-11 (QA task): hard gate for Story 3.0 merge

### 1. Widget test — `route_map_preview.dart` (WRITE BEFORE 3.0 PR)

File: `test/shared/widgets/map/route_map_preview_test.dart`

Minimum test cases:
- **Loading state:** supply a non-empty `meetingPoint`; stub `PlaceService.geocode` to hang → expect spinner overlay visible.
- **Error state:** stub `PlaceService.geocode` to throw `DioException`; expect error banner rendered, no crash.
- **Data state:** stub `PlaceService.geocode` to return `GeocodeResultDto(latitude, longitude, formattedAddress)` for origin only; expect `MapWidget` rendered.
- **Empty state:** both `meetingPoint` and `destination` null → expect "Vista previa del mapa" placeholder text.

Use `mocktail` for `PlaceService` stub (already in dev dependencies per ADR-1).

### 2. Zero `google_maps_flutter` / `geocoding` imports

```bash
grep -r "google_maps_flutter\|package:geocoding" lib/
# Must return zero lines
```

Run this in the PR review checklist before approving 3.0.

### 3. `dart analyze` — zero after 3.0 merge

```bash
dart analyze
# Expected: No issues found!
```

### 4. `flutter test` — no new failures

Baseline from pre-3.0: 28 passing, 4 pre-existing failures (stale `.g.dart`). After 3.0 merge: 29+ passing (new `route_map_preview_test.dart`), 4 pre-existing failures maximum.

---

## Physical device tests (mandatory for Story 3.5 merge)

### Android background GPS

Device: physical Android (Samsung or Xiaomi preferred — aggressive battery optimization).

Test plan:
1. Build and install debug APK.
2. Grant "Allow all the time" location permission.
3. Open a test event in `IN_PROGRESS` state; enter tracking.
4. Press home button (app backgrounded).
5. Verify "Rideglory — Rodada activa" persistent notification visible in notification shade (not dismissable).
6. Wait 60 seconds. Check WS server logs for continued location updates every ~5s.
7. Attach `adb logcat -s BackgroundTrackingService` output as PR artifact.

### iOS background location

Device: physical iPhone.

Test plan:
1. Build and install via Xcode (release-profile scheme).
2. Grant "Always" location permission.
3. Open tracking screen; background the app.
4. Verify blue location indicator in system status bar.
5. Wait 60 seconds. Check WS server logs for continued updates.
6. Attach Xcode console log as PR artifact.

**Both logs must be attached as PR artifacts before Story 3.5 merges.**

---

## Acceptance criteria traceability

| AC | Story | Verification |
|----|-------|--------------|
| Mapbox only, Google removed | US-3-0 | `grep -r google_maps_flutter\|geocoding lib/` → 0 lines |
| `dart analyze` zero | US-3-8 | `dart analyze` → `No issues found!` |
| No new test failures | US-3-8 | `flutter test` count ≥ baseline |
| Widget test passes before 3.0 PR | US-3-8 | `flutter test test/shared/widgets/map/route_map_preview_test.dart` passes |
| Info.plist location strings in Spanish | US-3-0 | Open `ios/Runner/Info.plist`; verify `NSLocationWhenInUseUsageDescription` and `NSLocationAlwaysAndWhenInUseUsageDescription` are written in Spanish |
| No hardcoded strings in new widgets | US-3-8 | `git diff --name-only HEAD~1 HEAD | xargs grep -l '"[A-ZÁÉÍÓÚa-záéíóú]' --include="*.dart"` → new widget files show zero hardcoded Spanish string literals; all in `app_es.arb` |
| Android foreground service log | US-3-5 | Device log attached to PR |
| iOS background location log | US-3-5 | Xcode log attached to PR |
| SOS processed < 5s | US-3-1 | Manual test: measure time from SOS confirm tap to other rider's banner appearing |
| Event end push < 10s | US-3-4 | Manual test: measure time from "Terminar rodada" confirm to FCM push receipt |

---

## `app_es.arb` verification

```bash
git diff main..iter-3 -- lib/l10n/app_es.arb
# Must be non-empty (new keys added for SOS, tracking, route adherence strings)
```

All new l10n keys should use prefixes: `sos_`, `tracking_`, `map_`, `vehicle_`.

---

## Pre-existing failures (do not regress)

4 tests fail on `main` due to stale `.g.dart` files (`user_service.g.dart`, `event_service.g.dart`). After `build_runner build` in iter-3 pre-flight, these should regenerate and clear. If they do not, document and treat as blocking.

> Full detail: docs/handoffs/architect.md
