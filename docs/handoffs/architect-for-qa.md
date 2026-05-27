> Slim handoff — read this before docs/handoffs/architect.md

# Architect → QA — Iteration 6 (refactor-01)

**Date:** 2026-05-27

---

## Pre-refactor baseline (capture before frontend starts)

```bash
dart analyze lib/ 2>&1 | tee /tmp/analyze_baseline.txt
flutter test 2>&1 | tail -10 | tee /tmp/test_baseline.txt
```

Expected baseline: 2 warnings in `api_base_url_resolver.dart` lines 17–19 (out of scope — acceptable throughout); 0 elsewhere. TC-2-28 is a pre-existing failure (unrelated) — document but do not count as regression.

---

## Post-refactor mandatory DoD grep checks (run all — must return 0)

```bash
# REFACTOR-01: SOAT button
grep -rn "soat_downloading" lib/features/soat/presentation/widgets/soat_data_view.dart

# REFACTOR-02: SOAT consolidation
find lib/features/vehicles/presentation/soat -name "*.dart" 2>/dev/null | wc -l
grep -r "vehicles/presentation/soat" lib/ --include="*.dart"
grep "soatManualCapture" lib/shared/router/app_routes.dart
grep "\/vehicles\/soat" lib/shared/router/app_router.dart  # must still exist (=1)

# REFACTOR-07: Raw buttons
grep -rn "ElevatedButton\|OutlinedButton\|TextButton" lib/features/ --include="*.dart" | grep -v "// Custom:"

# REFACTOR-08: FormBuilderTextField
grep -rn "FormBuilderTextField" lib/features/ --include="*.dart"

# REFACTOR-09 + REFACTOR-02: Navigator
grep -rn "Navigator\.of(context)\." lib/features/ --include="*.dart" | grep -v "// Custom:"
grep -rn "Navigator\.pop(context" lib/features/ --include="*.dart" | grep -v "SystemNavigator\|// Custom:"

# REFACTOR-10: goNamed
grep -rn "context\.goNamed" lib/features/ --include="*.dart" | grep -v "// Intentional:"

# REFACTOR-11: Hardcoded colors
grep -rn "Color(0x" lib/features/ --include="*.dart" | grep -v "// Intentional:"
grep -rn "Colors\." lib/features/ --include="*.dart" | grep -v "// Intentional:"

# REFACTOR-12: Exception comment present
grep "isLoadingMore" lib/features/notifications/presentation/cubit/notifications_state.dart
grep "// Exception:" lib/features/notifications/presentation/cubit/notifications_state.dart

# REFACTOR-13: showDialog
grep -rn "showDialog(" lib/features/ --include="*.dart" | grep -v "// Custom:\|AppDialog\|ConfirmationDialog"

# REFACTOR-14: Old form headers eliminated
grep -rn "VehicleFormNavHeader\|MaintenanceFormNavHeader" lib/ --include="*.dart"
test -f lib/design_system/molecules/app_form_nav_header.dart && echo "EXISTS" || echo "MISSING"

# One-widget-per-file: authentication
find lib/features/authentication -name "*.dart" | while read f; do
  count=$(grep -cE "extends (StatelessWidget|StatefulWidget|PreferredSizeWidget)" "$f" 2>/dev/null)
  if [ "${count:-0}" -gt 1 ] 2>/dev/null; then echo "$count $f"; fi
done

# One-widget-per-file: vehicles
find lib/features/vehicles/presentation -name "*.dart" | while read f; do
  count=$(grep -cE "extends (StatelessWidget|StatefulWidget|PreferredSizeWidget)" "$f" 2>/dev/null)
  if [ "${count:-0}" -gt 1 ] 2>/dev/null; then echo "$count $f"; fi
done

# One-widget-per-file: events
find lib/features/events/presentation -name "*.dart" | while read f; do
  count=$(grep -cE "extends (StatelessWidget|StatefulWidget|PreferredSizeWidget)" "$f" 2>/dev/null)
  if [ "${count:-0}" -gt 1 ] 2>/dev/null; then echo "$count $f"; fi
done

# One-widget-per-file: maintenance
find lib/features/maintenance -name "*.dart" | while read f; do
  count=$(grep -cE "extends (StatelessWidget|StatefulWidget|PreferredSizeWidget)" "$f" 2>/dev/null)
  if [ "${count:-0}" -gt 1 ] 2>/dev/null; then echo "$count $f"; fi
done

# One-widget-per-file: home/profile/users/event_registration
find lib/features/home lib/features/profile lib/features/users lib/features/event_registration -name "*.dart" | while read f; do
  count=$(grep -cE "extends (StatelessWidget|StatefulWidget|PreferredSizeWidget)" "$f" 2>/dev/null)
  if [ "${count:-0}" -gt 1 ] 2>/dev/null; then echo "$count $f"; fi
done

# Widget-returning methods (all features)
grep -rn "Widget _build\|Widget _[a-z]" lib/features/ --include="*.dart" | grep -v "// Custom:\|//"

# REFACTOR-15: ARB key count
jq -r 'keys[] | select(startswith("@") | not)' lib/l10n/app_es.arb | wc -l
# Must be ≤1220 (target: ≥10% reduction from 1357)

# No stale l10n references
grep -rn "context\.l10n\." lib/features/ --include="*.dart" \
  | awk -F'context.l10n.' '{print $2}' \
  | awk -F'[^a-zA-Z0-9_]' '{print $1}' \
  | sort -u > /tmp/used_keys_post.txt
jq -r 'keys[] | select(startswith("@") | not)' lib/l10n/app_es.arb | sort > /tmp/arb_keys_post.txt
comm -23 /tmp/used_keys_post.txt /tmp/arb_keys_post.txt | wc -l
# Must be 0 (no used key missing from ARB)
```

---

## Final quality gates

```bash
dart analyze lib/
# Expected: 2 warnings in api_base_url_resolver.dart ONLY; 0 elsewhere

flutter test
# Expected: same pass count as baseline; TC-2-28 still acceptable; 0 new failures
```

---

## Mandatory manual smoke tests (HARD acceptance criteria)

Run on device or emulator. Mark each with pass/fail before merging.

| # | Feature | Steps | Hard AC? |
|---|---------|-------|---------|
| 1 | SOAT upload flow | Vehicle detail → SOAT badge → upload page → manual capture form → save → back → status refreshes | Yes |
| 2 | SOAT vehicle creation | Vehicle form → SOAT section → attach photo → confirmation page → save | Yes |
| 3 | SOAT status view | SOAT status → "Edit" → manual capture → save → status refreshes | Yes |
| 4 | Login ↔ ForgotPassword | Login → tap "Forgot password" → enter email → back to Login | Yes |
| 5 | Signup end-to-end | Signup page start to account creation | Yes |
| 6 | Event detail CTA bar — all 4 variants | View event as: (a) registered rider, (b) pending approval, (c) closed/full event, (d) event organizer | **HARD — no widget tests exist** |
| 7 | Maintenance filters | Maintenance list → open filters → select type → apply → list filters correctly | Yes |
| 8 | Garage options | Garage → long-press vehicle → archive / delete / set-main — all 3 actions work | Yes |
| 9 | Vehicle form (create + edit) | AppFormNavHeader renders correctly; loading state visible on save | Yes |
| 10 | Maintenance form | Progress bars visible in bottom slot; "Listo" pill works | Yes |
| 11 | Event form (create + edit) | Both "Nuevo Evento" and "Editar Evento" variants; loading visible on publish | Yes |
| 12 | AI cover generation regression | Event form → generate cover → select image → save event → confirm functional | Yes |
| 13 | Mapbox route preview regression | Event form → route tab → map preview renders correctly post-extraction | Yes |
| 14 | 15-screen navigation (l10n) | Navigate all major screens; confirm no missing-translation strings appear | Yes |

---

## Story-to-REFACTOR mapping for QA tracking

| Task | REFACTOR ID | Mechanical check |
|------|------------|-----------------|
| T-6-1 | REFACTOR-01 | grep soat_downloading = 0 |
| T-6-2 | REFACTOR-02 | find vehicles/presentation/soat = 0; grep vehicles/presentation/soat = 0 |
| T-6-3 | REFACTOR-10 | grep context.goNamed \| grep -v Intentional = 0 |
| T-6-4 | REFACTOR-08 | grep FormBuilderTextField lib/features = 0 |
| T-6-5 | REFACTOR-07 | grep ElevatedButton\|TextButton\|OutlinedButton lib/features \| grep -v Custom = 0 |
| T-6-6 | REFACTOR-13 | grep showDialog lib/features \| grep -v Custom\|AppDialog = 0 |
| T-6-7 | REFACTOR-11 | grep Color(0x lib/features \| grep -v Intentional = 0 |
| T-6-8 | REFACTOR-04 | widget-class check auth = 0 lines |
| T-6-9 | REFACTOR-03a | widget-class check vehicles/garage = 0 lines |
| T-6-10 | REFACTOR-03b | widget-class check vehicles/presentation = 0 lines |
| T-6-11 | REFACTOR-05a | widget-class check events/detail = 0 lines; 4-variant smoke test |
| T-6-12 | REFACTOR-05b | widget-class check events/form+tracking+list+drafts = 0 lines |
| T-6-13 | REFACTOR-06a | widget-class check maintenance = 0 lines |
| T-6-14 | REFACTOR-06b | widget-class check home+profile+users+event_registration = 0 lines |
| T-6-15 | REFACTOR-09 | grep Navigator.of(context). \| grep -v Custom = 0; grep Navigator.pop(context \| grep -v Custom = 0 |
| T-6-16 | REFACTOR-14 | file exists; grep VehicleFormNavHeader\|MaintenanceFormNavHeader = 0 |
| T-6-17 | REFACTOR-15 | arb key count ≤1220; no stale references |

> Full detail: docs/handoffs/architect.md

---

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
