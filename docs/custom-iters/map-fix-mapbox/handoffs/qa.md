# QA → Tech Lead Handoff — map-fix-mapbox

**QA completed at:** 2026-05-16T22:46:37Z

---

## Gate results

| Gate | Status | Notes |
|------|--------|-------|
| Gate 1 — File verification (code review) | PASS | All 8 claimed files verified correct |
| Gate 2 — dart analyze (0 errors) | PASS | 0 errors; 2 pre-existing info deprecation warnings unchanged |
| Gate 3 — dart format clean | PASS (after fix) | 2 files required formatting; fixed by QA and documented below |
| Gate 4 — Regression guard (no forbidden files) | PASS | No android/, cubit/, domain/, or data/ files touched |
| Gate 5 — flutter test baseline held | PASS | Only TC-2-28 failed (pre-existing); no new failures |
| Manual code review (5 checks) | PASS | All 5 checks passed |

---

## Files verified

| File | Status | Notes |
|------|--------|-------|
| `lib/main.dart` | ✓ | `assert` present with correct message; `MapboxOptions.setAccessToken(mapboxToken!)` unconditional at line 45 |
| `ios/Runner/Info.plist` | ✓ | `MBXAccessToken` key present at line 76 with literal `pk.eyJ1IjoiY2FtaWlsbzkyIi...` token; NOT using `$(MAPBOX_PUBLIC_TOKEN)` |
| `lib/shared/widgets/map/route_map_preview.dart` | ✓ | `bool _mapLoadError = false` field at line 35; condition `_hasCoordsToShow && !_mapLoadError` at line 226; `onMapLoadErrorListener` wired with `setState(() => _mapLoadError = true)` |
| `lib/features/events/presentation/tracking/widgets/live_map_widget.dart` | ✓ | `final ValueChanged<String>? onMapError` field at line 25; `onMapLoadErrorListener` calls `widget.onMapError?.call(data.message)` |
| `lib/features/events/presentation/tracking/widgets/live_map_body.dart` | ✓ | `onMapError` callback wired; `removeCurrentSnackBar()` called before `showSnackBar()` at lines 68–70; uses `context.l10n.map_loadError` |
| `lib/l10n/app_es.arb` | ✓ | `map_loadError` key with value `"No se pudo cargar el mapa."` and `@map_loadError` metadata present |
| `lib/l10n/app_localizations.dart` | ✓ | `String get map_loadError` abstract getter present |
| `lib/l10n/app_localizations_es.dart` | ✓ | `String get map_loadError => 'No se pudo cargar el mapa.'` implementation present |

---

## Fixes applied

### Fix 1 — dart format on route_map_preview.dart

**Why:** `dart format --output=none` reported this file as needing formatting changes (formatting was not run by Frontend before commit).

**Action:** Ran `dart format lib/shared/widgets/map/route_map_preview.dart`. No semantic changes — purely whitespace/line-length normalization from the formatter.

### Fix 2 — dart format on live_map_body.dart

**Why:** Same as Fix 1 — `dart format --output=none` reported this file as needing formatting.

**Action:** Ran `dart format lib/features/events/presentation/tracking/widgets/live_map_body.dart`. No semantic changes.

**Verification:** Re-ran `dart format --output=none` on all 4 Frontend-modified `.dart` files after applying fixes — 0 files changed. Re-ran `dart analyze lib/` — still 0 errors.

---

## dart analyze output

```
Analyzing lib...

   info - shared/widgets/map/route_map_preview.dart:136:38 - 'cameraForCoordinates' is deprecated and shouldn't be used. Use [cameraForCoordinatesPadding] instead. Try replacing the use of the deprecated member with the replacement. - deprecated_member_use
   info - shared/widgets/map/route_map_preview.dart:225:19 - 'cameraOptions' is deprecated and shouldn't be used. Use [viewport] to specify the camera position and behavior of the map. Try replacing the use of the deprecated member with the replacement. - deprecated_member_use

2 issues found.
```

Note: Line numbers shifted by 3 from the pre-format output (133→136, 228→225) because formatting changed the file. Both warnings are identical pre-existing deprecations in the unchanged `_fitMapBounds` and `build` methods. Zero errors — gate PASSES.

---

## flutter test output

```
00:05 +47 -1: Some tests failed.
```

**Summary:** 47 tests passed, 1 failed.

**Failed test:** `RiderProfilePage — State Display Tests (US-2-3) TC-2-28: Data state shows rider email`
- File: `test/features/users/presentation/pages/rider_profile_page_test.dart:97`
- Failure: `Expected: at least one matching candidate — Actual: _TextWidgetFinder:<Found 0 widgets with text "juan@example.com": []>`
- This is the known pre-existing TC-2-28 failure documented in the architect and frontend handoffs.

**No new test failures were introduced by this iteration.** Gate PASSES.

---

## Regression guard

`git diff --name-only` output for the working tree:

```
docs/custom-iters/map-fix-mapbox/PRD_NORMALIZED.md
docs/custom-iters/map-fix-mapbox/_meta.json
ios/Runner/Info.plist
lib/features/events/presentation/tracking/widgets/live_map_body.dart
lib/features/events/presentation/tracking/widgets/live_map_widget.dart
lib/l10n/app_es.arb
lib/l10n/app_localizations.dart
lib/l10n/app_localizations_es.dart
lib/main.dart
lib/shared/widgets/map/route_map_preview.dart
```

**Checks:**

| Guardrail | Status | Detail |
|-----------|--------|--------|
| No `android/` files | PASS | No android files in diff |
| No `lib/**/cubit/` files | PASS | No cubit files in diff |
| No `lib/**/domain/` files | PASS | No domain files in diff |
| No `lib/**/data/` files | PASS | No data files in diff |
| `app_es.arb` diff is minimal | PASS | Only `map_loadError` key + `@map_loadError` metadata added; no other key changes (confirmed via `git diff lib/l10n/app_es.arb`) |

---

## Manual code review

### Check 1 — `onMapLoadErrorListener` callback type matches `void Function(MapLoadingErrorEventData)`

PASS. Both usages pass an anonymous function of type `(MapLoadingErrorEventData data) { ... }`:
- `route_map_preview.dart:241`: `onMapLoadErrorListener: (MapLoadingErrorEventData data) { ... }`
- `live_map_widget.dart:152`: `onMapLoadErrorListener: (MapLoadingErrorEventData data) { ... }`

This matches the Mapbox 2.23.1 `OnMapLoadErrorListener` typedef which expects `void Function(MapLoadingErrorEventData)`.

### Check 2 — `import ... hide Error` still intact in route_map_preview.dart

PASS. Line 4 of `route_map_preview.dart` reads:
```dart
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart' hide Error;
```
The `hide Error` is preserved after formatting. Note: `live_map_body.dart` uses a plain import without `hide Error` (line 3), which is correct — that file does not use `Error` or any conflicting type from mapbox.

### Check 3 — `MapLoadingErrorEventData` does NOT conflict with `hide Error`

PASS. The `hide Error` in `route_map_preview.dart` hides the Mapbox `Error` class to avoid a name collision with Dart's built-in `Error`. `MapLoadingErrorEventData` is a separate class — it is not `Error` — so there is no conflict. The type is used correctly in both files.

### Check 4 — `live_map_body.dart` uses `context.l10n.map_loadError` and key exists

PASS. `live_map_body.dart:70` shows `context.l10n.map_loadError`.
- `app_es.arb` contains the key `"map_loadError": "No se pudo cargar el mapa."` at line 1274.
- `app_localizations.dart` exposes `String get map_loadError` (abstract getter confirmed by grep).
- `app_localizations_es.dart` implements `String get map_loadError => 'No se pudo cargar el mapa.'`.

### Check 5 — `removeCurrentSnackBar()` called before `showSnackBar()` in live_map_body.dart

PASS. The callback in `live_map_body.dart` at lines 66–74:
```dart
onMapError: (message) {
  final messenger = ScaffoldMessenger.of(context);
  messenger.removeCurrentSnackBar();
  messenger.showSnackBar(
    SnackBar(content: Text(context.l10n.map_loadError)),
  );
},
```
`removeCurrentSnackBar()` at line 68 precedes `showSnackBar()` at line 69. Deduplication is correct.

---

## Verdict

**PASS**

All 6 quality gates passed (Gate 3 passed after QA applied 2 minor formatting fixes). No new errors, no new test failures, no forbidden files modified. All 8 claimed files verified as correctly implementing the specified behavior.

The iteration is ready for Tech Lead review.

---

## Notes for Tech Lead

1. **dart format not run by Frontend before handoff.** Two files (`route_map_preview.dart` and `live_map_body.dart`) were unformatted. QA applied `dart format` — no semantic changes, purely whitespace. This is a minor process gap to note in feedback to Frontend.

2. **`_mapLoadError` is not reset on widget rebuild** (sticky error state). Once `_mapLoadError = true` is set in `_RouteMapPreviewState`, it persists for the lifetime of the widget instance. This is the intended behavior per the architect handoff ("Navigating away and back should reset it — new state instance"). Tech Lead may want to verify this is acceptable UX or whether a retry button should be added in a follow-up.

3. **Info.plist token is a literal hardcoded pk.* token.** This was an explicit architect decision (documented in `_meta.json`: "Decision flip from PRD: use literal pk token in Info.plist instead of `$(MAPBOX_PUBLIC_TOKEN)` — confirmed via grep that no xcconfig defines that build variable"). The token is a public Mapbox token (read-only, not a secret) so this is acceptable. Tech Lead should confirm this is committed to the repo intentionally.

4. **iOS simulator smoke test and Android regression test cannot be performed by automated QA** — device testing is out of scope per the architect handoff (§ "What QA does NOT need to do"). Tech Lead or a human tester should execute the smoke matrix before merging.

5. **Pre-existing TC-2-28 test failure remains unfixed** — this is explicitly accepted per the architect sign-off criteria.
