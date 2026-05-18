# PRD_NORMALIZED — Fix Mapbox Map (Black Screen)

**Slug:** map-fix-mapbox
**Type:** bug_fix
**Severity:** high — core feature (event route preview + live ride tracking) completely non-functional on both platforms
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
- **Design changes:** none — reuses existing placeholder UI
- **DB changes:** none

---

## § 4 Affected Areas

| File | Current State | Change |
|------|--------------|--------|
| `ios/Runner/Info.plist` | No `MBXAccessToken` key present; native Mapbox SDK initializes without a token before Dart runs | Add `<key>MBXAccessToken</key><string>$(MAPBOX_PUBLIC_TOKEN)</string>` using the build-variable form so the value is injected at build time |
| `lib/main.dart` | Token set is wrapped in a null-and-empty guard: `if (mapboxToken != null && mapboxToken.isNotEmpty) { MapboxOptions.setAccessToken(mapboxToken); }` — silently no-ops if token is missing | Replace with fail-fast `assert` + unconditional `MapboxOptions.setAccessToken(mapboxToken!)` |
| `lib/shared/widgets/map/route_map_preview.dart` | `MapWidget` has no `onMapLoadError` handler; style/tile failures are invisible (silent black surface) | Add `_mapLoadError` bool field to `_RouteMapPreviewState`; wire `onMapLoadError` to set it; when true, replace the map surface with the existing "no coordinates" placeholder (map icon + subtitle text) |
| `lib/features/events/presentation/tracking/widgets/live_map_widget.dart` | `MapWidget` has no error handler; failure renders a black surface during an active ride | Add `onMapLoadError` handler (and optional `onMapError` callback on `LiveMapWidget`) so the parent (`LiveMapBody`) can show a `SnackBar` fallback instead of silence |

---

## § 5 Root Causes

### Root Cause 1 — iOS: `MBXAccessToken` missing from `Info.plist` (critical)

The Mapbox iOS SDK (v11, wrapped by `mapbox_maps_flutter` 2.23.1) performs its native initialization **before** the Dart isolate starts. If `MBXAccessToken` is absent from `Info.plist`, the native SDK boots without a token and tile/style requests fail immediately. By the time `main.dart` calls `MapboxOptions.setAccessToken()`, those requests have already been rejected.

Android is not affected because the public token is injected at build time via a manifest placeholder in `android/app/build.gradle.kts`.

Confirmed: `ios/Runner/Info.plist` has no `MBXAccessToken` key (verified by reading the file; the only relevant native key is the location usage string).

### Root Cause 2 — Both platforms: No map load error surface

When the Mapbox style fails to load (wrong token, network issue, missing scope), `MapWidget` renders a solid black surface with no visual feedback. Neither `RouteMapPreview` nor `LiveMapWidget` register an `onMapLoadError` handler, so failures are completely silent.

Confirmed in source:
- `lib/shared/widgets/map/route_map_preview.dart`: `MapWidget` in `build()` has only `onMapCreated` — no error handler.
- `lib/features/events/presentation/tracking/widgets/live_map_widget.dart`: `MapWidget` in `build()` has only `onMapCreated` — no error handler.

### Root Cause 3 — Conditional token set in `main.dart` (defensive gap)

Current code in `lib/main.dart` (lines 40–43):
```dart
const mapboxToken = AppEnv.mapboxPublicToken;
if (mapboxToken != null && mapboxToken.isNotEmpty) {
  MapboxOptions.setAccessToken(mapboxToken);
}
```

`AppEnv.mapboxPublicToken` is declared `String?` (optional field) in `lib/core/config/app_env.dart` and baked in at compile time via `envied`. In a correctly configured build the token is never null. However, the conditional guard means a missing or empty token silently skips initialization — which is the same symptom as the iOS root cause. A fail-fast assertion makes the misconfiguration immediately visible during development.

---

## § 6 Acceptance Criteria

1. Opening an event detail page on **Android emulator** renders the Mapbox dark style map with tiles — not a black screen.
2. Opening an event detail page on **iOS simulator** renders the Mapbox dark style map with tiles — not a black screen.
3. Opening an event detail page on a **physical Android device** renders the map correctly.
4. Opening an event detail page on a **physical iOS device** renders the map correctly.
5. When the Mapbox token is invalid **or** the device is offline, `RouteMapPreview` shows the map icon + subtitle placeholder, **not** a black rectangle.
6. When map load fails in `LiveMapWidget`, the `onMapError` callback is invoked (verified by code review); `LiveMapBody` shows a `SnackBar` error instead of silence.
7. `dart analyze lib/` produces **0 errors**. The pre-existing unused-element warning on `_formatKm` is acceptable and must not increase.
8. The app launches without crashing on either platform after all four changes are applied.

---

## § 7 Regression Guardrails

| Area | Guardrail | Verification |
|------|-----------|--------------|
| Android map (existing) | `MAPBOX_ACCESS_TOKEN` in `local.properties` and manifest placeholder in `build.gradle.kts` are unchanged | `git diff android/` shows no removals of the existing token wiring |
| Route map geocoding | `_geocodeAddress`, `_fitMapBounds`, and `_updateAnnotations` logic in `route_map_preview.dart` unchanged | Code review diff — only `_mapLoadError` field and `MapWidget.onMapLoadError` callback added |
| Live tracking annotations | `_updateAnnotations`, `InitialsMarkerIcon`, and `LiveMapController` unchanged | Code review diff — only error handler added to `MapWidget` in `build()` |
| Localization | No new `app_es.arb` keys are required — the placeholder text reuses strings already in `RouteMapPreview`; the `SnackBar` in `LiveMapBody` may use an existing key | `dart analyze` + `flutter gen-l10n` produces no errors; `app_es.arb` diff minimal |
| DI / cubits | No cubit, repository, or use case changes | No files under `lib/**/cubit/`, `lib/**/domain/`, or `lib/**/data/` are modified |
| flutter test | All existing passing tests remain green | `flutter test` output unchanged (1 pre-existing fail TC-2-28 is acceptable) |

---

## § 8 Developer Setup Prerequisite (iOS)

This is a developer machine configuration step, not a code change. It must be completed on any machine that runs `pod install` for the first time.

Add `~/.netrc` on the developer machine:

```
machine api.mapbox.com
  login mapbox
  password {MAPBOX_DOWNLOADS_TOKEN}
```

Where `{MAPBOX_DOWNLOADS_TOKEN}` is the secret `sk.*` token from `~/.gradle/gradle.properties`.

Then run:
```bash
cd ios && pod install
```

Without this file, CocoaPods cannot authenticate to `api.mapbox.com` and the Mapbox XCFramework (~200 MB) download fails. If `ios/Pods/` already exists (cached from a previous install), this does not block the current build — but future `pod install` runs will fail.

Document location: add this requirement to `DEPLOY.md` under an "iOS Setup" section.

---

## § 9 Open Questions

None. The PRD fully specifies all four affected files, root causes, and acceptance criteria. The `mapbox_maps_flutter` API for `onMapLoadError` is available in version 2.23.1 (the resolved version confirmed in `pubspec.lock`). No design work is needed — the placeholder UI already exists in `RouteMapPreview`.
