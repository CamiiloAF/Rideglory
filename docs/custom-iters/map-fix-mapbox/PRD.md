# PRD — Fix Mapbox Map (Black Screen)

## Problem

The map renders as a black screen on both Android and iOS. No tiles or style are visible. This affects two features:
- **Route map preview** — shown in event detail pages (`RouteMapPreview`)
- **Live tracking map** — shown during active rides (`LiveMapWidget`)

## Root Causes (Diagnosed)

### 1. iOS: `MBXAccessToken` missing from `Info.plist` (critical)
The Mapbox iOS SDK (v11, wrapped by `mapbox_maps_flutter` 2.23.1) initializes natively before the Dart isolate starts. If `MBXAccessToken` is absent from `Info.plist`, the native SDK boots without a token. By the time `main.dart` calls `MapboxOptions.setAccessToken()`, tile requests have already failed. Android does not have this problem because the token is injected via manifest placeholder at build time.

### 2. Both platforms: No map load error surface
When the Mapbox style fails to load (wrong token, network issue, scope problem), `MapWidget` just shows a black surface. Neither `RouteMapPreview` nor `LiveMapWidget` register an error handler on style loading, so failures are silent.

### 3. Token scope validation not enforced at startup
The public token `pk.*` must have the scopes `styles:read`, `tiles:read`, `maps:read`. There is no startup check that validates the token is active and has the right scopes. A revoked or under-scoped token causes the same black-screen symptom.

## Keys Available in the Project

| Key | Location | Value prefix |
|-----|----------|-------------|
| Public token (`pk.*`) | `.env` → `MAPBOX_PUBLIC_TOKEN`, `local.properties` → `MAPBOX_ACCESS_TOKEN`, baked into `app_env.g.dart` | `pk.eyJ1IjoiY2FtaWlsbzky...` |
| Downloads/secret token (`sk.*`) | `~/.gradle/gradle.properties` → `MAPBOX_DOWNLOADS_TOKEN` | `sk.eyJ1IjoiY2FtaWlsbzky...` |

The public token is used at runtime (tile/style requests). The secret token is used at build time to download the SDK from Mapbox's private Maven/CocoaPods repositories.

## Goals

1. Map renders correctly on Android (emulator + physical device)
2. Map renders correctly on iOS (simulator + physical device)
3. When the map fails to load, a visible error state is shown instead of a black screen
4. `dart analyze` passes with 0 issues after all changes

## Non-Goals

- Offline map support
- Custom map styles beyond the existing `DARK` and `STANDARD` presets
- Changing the map library or token

---

## Required Changes

### A. iOS `Info.plist` — add `MBXAccessToken`

**File:** `ios/Runner/Info.plist`

Add the following key/value pair (public token is safe to embed — `pk.*` keys are intended to be client-side):

```xml
<key>MBXAccessToken</key>
<string>$(MAPBOX_PUBLIC_TOKEN)</string>
```

This ensures the Mapbox native SDK has a token during its native initialization phase, before Dart code runs.

### B. `main.dart` — remove conditional token set

**File:** `lib/main.dart`

Current code uses a nullable guard:
```dart
const mapboxToken = AppEnv.mapboxPublicToken;
if (mapboxToken != null && mapboxToken.isNotEmpty) {
  MapboxOptions.setAccessToken(mapboxToken);
}
```

Since `AppEnv.mapboxPublicToken` is baked in at compile time via `envied` and is never null in a real build, the guard is unnecessary. Replace with a fail-fast assertion that throws clearly if the token is missing:

```dart
final mapboxToken = AppEnv.mapboxPublicToken;
assert(mapboxToken != null && mapboxToken!.isNotEmpty, 'MAPBOX_PUBLIC_TOKEN must be set in .env');
MapboxOptions.setAccessToken(mapboxToken!);
```

### C. `RouteMapPreview` — add map load error state

**File:** `lib/shared/widgets/map/route_map_preview.dart`

Add a `_mapLoadError` bool field to `_RouteMapPreviewState`. Wire `MapWidget.onMapLoadError` (or `onStyleLoadedListener`) to set this flag. When `_mapLoadError` is true, replace the black map surface with the existing "no coordinates" placeholder (map icon + explanation text).

### D. `LiveMapWidget` — add map load error handler

**File:** `lib/features/events/presentation/tracking/widgets/live_map_widget.dart`

Add `onMapLoadError` (or equivalent `onStyleLoaded` listener) to `MapWidget`. On failure, emit an error state up to `LiveMapBody` so the live map page can show a snack bar or fallback UI instead of a black screen.

### E. iOS developer setup — `.netrc` documentation

**Not a code change.** The Mapbox iOS SDK is fetched from `api.mapbox.com` via CocoaPods. This requires `~/.netrc` on the developer machine:

```
machine api.mapbox.com
  login mapbox
  password sk.eyJ1IjoiY2FtaWlsbzky...{secret token}
```

Without this file, `pod install` cannot download the Mapbox XCFramework. If the `ios/Pods/` directory already exists (committed or cached), this may not block the build, but any future `pod install` will fail.

This must be documented in the project `README` or `DEPLOY.md`.

---

## Affected Files

| File | Change | Layer |
|------|--------|-------|
| `ios/Runner/Info.plist` | Add `MBXAccessToken` key | Native / iOS config |
| `lib/main.dart` | Replace conditional with assertion + unconditional `setAccessToken` | App entrypoint |
| `lib/shared/widgets/map/route_map_preview.dart` | Add `_mapLoadError` state, wire `onMapLoadError`, show error fallback | Presentation |
| `lib/features/events/presentation/tracking/widgets/live_map_widget.dart` | Add error handler on map load failure | Presentation |

---

## Acceptance Criteria

1. Running the app on Android (emulator or device) and opening an event detail page shows the Mapbox dark map with tiles rendered — not a black screen.
2. Running the app on iOS simulator and opening an event detail page shows the Mapbox dark map with tiles rendered — not a black screen.
3. Running the app on a physical iOS device and opening an event detail page shows the map correctly.
4. If the Mapbox token is invalid or the network is offline, `RouteMapPreview` shows the map placeholder (icon + text) instead of a black surface.
5. `dart analyze` produces 0 errors after all changes.
6. No new warnings introduced beyond the pre-existing `_formatKm` unused-element warning.

---

## Developer Setup Prerequisite (iOS)

Before building for iOS, ensure `~/.netrc` contains:

```
machine api.mapbox.com
  login mapbox
  password {MAPBOX_DOWNLOADS_TOKEN from ~/.gradle/gradle.properties}
```

Then run `cd ios && pod install` to fetch the Mapbox XCFramework.
