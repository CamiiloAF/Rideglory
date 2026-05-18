# Architect → QA Handoff — map-fix-mapbox

## What changed

Five files were touched (six if the new l10n key is added):

1. `lib/main.dart` — fail-fast assert + non-null assertion on Mapbox token
2. `ios/Runner/Info.plist` — added `MBXAccessToken` with literal `pk.*` token
3. `lib/shared/widgets/map/route_map_preview.dart` — new `_mapLoadError` field; on error renders existing placeholder
4. `lib/features/events/presentation/tracking/widgets/live_map_widget.dart` — new optional `onMapError` callback parameter
5. `lib/features/events/presentation/tracking/widgets/live_map_body.dart` — handles `onMapError` with a SnackBar
6. (optional) `lib/l10n/app_es.arb` — new `map_loadError` key

## Automated gates

| Gate | Command | Expected |
|------|---------|----------|
| Lint | `dart analyze lib/` | 0 errors. The pre-existing `_formatKm` unused-element warning is acceptable and must not increase. |
| Tests | `flutter test` | Match pre-iteration baseline. TC-2-28 may still fail (pre-existing). |
| Format | `dart format --output=none lib/` | No diff. |

No new widget tests are required for this iteration (Mapbox rendering cannot be widget-tested).

## Manual smoke matrix

Run each on a real device or emulator. Confirm the map renders dark-style tiles, not a black rectangle.

| # | Platform | Path | Expected |
|---|----------|------|----------|
| 1 | iOS simulator | Open any event → event detail page | `RouteMapPreview` map tiles render. |
| 2 | iOS simulator | Start a live ride → live tracking page | `LiveMapWidget` tiles render; rider markers visible. |
| 3 | iOS physical device | Same as #1 + #2 | Same expected results. |
| 4 | Android emulator | Same as #1 + #2 | No regression — map already worked, must still work. |
| 5 | Android physical device | Same as #1 + #2 | No regression. |

## Manual error-path smoke (critical — this is the bug we're fixing)

1. Edit `.env`, set `MAPBOX_PUBLIC_TOKEN=pk.invalidtokenforcetesting`.
2. Run `dart run build_runner build --delete-conflicting-outputs`.
3. Hot-restart the app (full restart, not hot reload — `envied` is compile-time).
4. **Event detail page:** `RouteMapPreview` must show the map icon + "Vista previa del mapa" / "Ingresa las dirección para ver la ruta" placeholder. **Not** a black rectangle.
5. **Live tracking page:** the map area may render partial or empty, but a SnackBar must appear with "No se pudo cargar el mapa." (or "No se pudo obtener las coordenadas." if the team kept the reused key).
6. **Restore** the real token in `.env`, rerun build_runner, restart app, confirm normal behavior returns.

## Crash-on-missing-token check (release-mode fail-fast)

1. Remove `MAPBOX_PUBLIC_TOKEN` from `.env` entirely (comment it out).
2. Run `dart run build_runner build --delete-conflicting-outputs`.
3. In **debug** mode: the `assert` fires immediately at startup with the message `MAPBOX_PUBLIC_TOKEN must be set in .env`. App does not boot.
4. In **release** mode (optional): asserts are stripped; `mapboxToken!` throws `Null check operator used on a null value` at the line of `setAccessToken`. App crashes at startup — this is the intended fail-fast behavior.
5. Restore the token before continuing other tests.

## Regression guardrails to verify (from PRD § 7)

- [ ] `git diff android/` shows no changes — Android wiring untouched.
- [ ] `_geocodeAddress`, `_fitMapBounds`, `_updateAnnotations` in `route_map_preview.dart` are byte-identical except for the new field/branch. Verify via `git diff`.
- [ ] `_loadMarkerIcons`, `_updateAnnotations`, `InitialsMarkerIcon`, `LiveMapController` in `live_map_widget.dart` are unchanged. Verify via `git diff`.
- [ ] No files modified under `lib/**/cubit/`, `lib/**/domain/`, or `lib/**/data/`.
- [ ] `app_es.arb` diff is at most one new `map_loadError` entry; no other key changes.

## Edge cases to keep an eye on

- **Snackbar spam during live tracking:** if Mapbox emits multiple `MapLoadingError` events (e.g. several failed tiles), the architect specified `removeCurrentSnackBar()` before each show — verify only one snackbar is visible at a time during the error-path smoke (step 5 above).
- **Placeholder persistence in `RouteMapPreview`:** once `_mapLoadError` is set to `true`, it stays `true` for the lifetime of the widget. Navigating away and back should reset it (new state instance). Confirm by repeating the error-path smoke after restoring the token — the placeholder should clear on re-entry.
- **iOS first-run after `flutter clean`:** if Pods/ is removed, `pod install` must succeed. If it fails with a Mapbox auth error, the developer machine is missing `~/.netrc` (see PRD § 8). This is a setup issue, not a bug in the fix.

## What QA does NOT need to do

- Add unit or widget tests for map rendering (out of scope).
- Verify Mapbox attribution UI or other style elements.
- Test offline mode beyond the error-path smoke.
- Touch the Android Mapbox wiring.

## Sign-off criteria

Iteration passes QA when:
- All automated gates green.
- Smoke matrix rows 1–5 pass on at least one iOS sim/device + one Android emulator/device.
- Error-path smoke (placeholder + SnackBar) passes on both platforms.
- Crash-on-missing-token check confirms assert fires in debug.
- No diffs outside the architect's change map.
