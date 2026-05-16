# PRD_NORMALIZED — Fix Mapbox Map (Black Screen)

**Slug:** map-fix-mapbox
**Type:** bug_fix
**Severity:** high — core feature (event route preview + live ride tracking) is completely non-functional on both platforms
**Normalized by PO on:** 2026-05-16

---

## § 1 Title

Mapbox Map Fix — Black Screen on Android and iOS (`MBXAccessToken` + Error Handling)

---

## § 2 Goal

Make the Mapbox map render correctly on Android and iOS by injecting the public token into `Info.plist` for iOS native initialization, adding a fail-fast assertion in `main.dart`, and surfacing a visible error state in both map widgets when style loading fails — so users never see a silent black screen.

---

## § 3 Type and Severity

- **Type:** bug_fix
- **Severity:** high
- **Breaking change:** none — all changes are additive or defensive
- **Backend changes:** none

---

## § 4 Root Causes

| # | Root Cause | Platform | Fix |
|---|-----------|----------|-----|
| 1 | `MBXAccessToken` absent from `ios/Runner/Info.plist` | iOS only | Add key to Info.plist with public token value |
| 2 | `MapWidget` has no error handler — style/tile failures are silent (black surface) | Both | Add `onMapLoadError` handler to `RouteMapPreview` and `LiveMapWidget` |
| 3 | Token set is conditional in `main.dart` — could silently no-op if env missing | Both | Replace with assertion + unconditional `setAccessToken` |

---

## § 5 Affected Areas

| File | Current State | Change |
|------|--------------|--------|
| `ios/Runner/Info.plist` | No `MBXAccessToken` key | Add `<key>MBXAccessToken</key>` with public token string |
| `lib/main.dart` | `if (mapboxToken != null && mapboxToken.isNotEmpty) setAccessToken(mapboxToken)` | Replace with assert + unconditional `setAccessToken(mapboxToken!)` |
| `lib/shared/widgets/map/route_map_preview.dart` | No error handler on `MapWidget`; black surface on failure | Add `_mapLoadError` state; wire `onMapLoadError`; show fallback placeholder |
| `lib/features/events/presentation/tracking/widgets/live_map_widget.dart` | No error handler on `MapWidget` | Add `onMapLoadError` handler; propagate error up |

---

## § 6 Token Reference (do not change)

| Key | Environment variable | Value (first 20 chars) |
|-----|---------------------|----------------------|
| Public (`pk.*`) | `MAPBOX_PUBLIC_TOKEN` in `.env` | `pk.eyJ1IjoiY2FtaWlsbzky…` |
| Downloads (`sk.*`) | `MAPBOX_DOWNLOADS_TOKEN` in `~/.gradle/gradle.properties` | `sk.eyJ1IjoiY2FtaWlsbzky…` |

The public token is baked into `app_env.g.dart` at compile time via `envied`. The downloads token is never embedded in app code — it is only used by the Android Gradle build and iOS CocoaPods to download the native SDK binary.

---

## § 7 Decisions Made

1. **Hardcode public token in `Info.plist`**: `pk.*` tokens are client-side by design — they are already in `.env`, `local.properties`, and `app_env.g.dart`. Hardcoding in `Info.plist` is the standard Mapbox iOS pattern and carries no additional security risk.
2. **Error fallback in `RouteMapPreview`**: Reuse the existing "no coordinates" placeholder (map icon + subtitle text) — no new UI design needed.
3. **Error propagation in `LiveMapWidget`**: Add a `onMapError` callback parameter so `LiveMapBody` can show a `SnackBar`. No full-page error screen needed for live map (ride is in progress, losing map is recoverable).
4. **No widget tests for map rendering**: Mapbox map rendering requires the native platform; Flutter widget tests cannot verify tile rendering. Acceptance is verified manually on device. `dart analyze` is the automated gate.
5. **`.netrc` is developer machine setup, not code**: Document in comments inside `ios/Podfile` and in the existing `DEPLOY.md` (or create it if absent). No code change.

---

## § 8 Acceptance Criteria

1. Opening an event detail page on **Android emulator** → map renders with Mapbox dark style tiles (not black).
2. Opening an event detail page on **iOS simulator** → map renders with Mapbox dark style tiles (not black).
3. Opening an event detail page on **physical Android device** → map renders correctly.
4. Opening an event detail page on **physical iOS device** → map renders correctly.
5. When `MapWidget` fails to load (offline / bad token) → `RouteMapPreview` shows the map icon placeholder, not a black rectangle.
6. `LiveMapWidget` calls `onMapError` callback (if provided) when map load fails — verified by code review.
7. `dart analyze lib/` → 0 errors (pre-existing unused-element warning on `_formatKm` is acceptable).
8. App launches without crashing on either platform after all changes.

---

## § 9 Regression Guardrails

| Area | Guardrail |
|------|-----------|
| Android map | Existing `MAPBOX_ACCESS_TOKEN` in `local.properties` + `build.gradle.kts` manifest placeholder still wired correctly — no change |
| Route map geocoding | `_geocodeAddress` + `_fitMapBounds` + annotation logic unchanged |
| Live tracking annotations | `_updateAnnotations` + `InitialsMarkerIcon` unchanged |
| Localization | No new l10n keys needed |
| DI / cubit | No cubit changes |

---

## § 10 iOS Developer Setup (Pre-flight)

Before building for iOS for the first time on a new machine, add `~/.netrc`:

```
machine api.mapbox.com
  login mapbox
  password {MAPBOX_DOWNLOADS_TOKEN}
```

Then run:
```bash
cd ios && pod install
```

Without this, `pod install` cannot download the Mapbox XCFramework from `api.mapbox.com`.
