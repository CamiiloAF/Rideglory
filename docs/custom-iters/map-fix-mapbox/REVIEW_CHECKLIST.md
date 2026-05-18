# Review Checklist — map-fix-mapbox

**Status:** Ready for human review
**Tech Lead verdict:** APPROVED
**QA verdict:** PASS

## What to review with `git diff`

| File | What to look for |
|------|-----------------|
| `lib/main.dart` | `assert` present with non-null + non-empty message; unconditional `MapboxOptions.setAccessToken(mapboxToken!)` call |
| `ios/Runner/Info.plist` | `MBXAccessToken` key with literal `pk.*` token placed after `#endif`, inside closing `</dict>` |
| `lib/shared/widgets/map/route_map_preview.dart` | `bool _mapLoadError = false` field; `_hasCoordsToShow && !_mapLoadError` condition; `onMapLoadErrorListener` wired with `setState(() => _mapLoadError = true)` |
| `lib/features/events/presentation/tracking/widgets/live_map_widget.dart` | `final ValueChanged<String>? onMapError` parameter; `onMapLoadErrorListener` calling `widget.onMapError?.call(data.message)` |
| `lib/features/events/presentation/tracking/widgets/live_map_body.dart` | `removeCurrentSnackBar()` called before `showSnackBar()`; `context.l10n.map_loadError` used |
| `lib/l10n/app_es.arb` | `map_loadError` key with value `"No se pudo cargar el mapa."` and `@map_loadError` metadata block |
| `lib/l10n/app_localizations.dart` | `String get map_loadError` abstract getter |
| `lib/l10n/app_localizations_es.dart` | `String get map_loadError => 'No se pudo cargar el mapa.'` implementation |

## Acceptance criteria checklist (PRD § 6)

- [ ] AC1: Android emulator — event detail shows Mapbox tiles (not black screen)
- [ ] AC2: iOS simulator — event detail shows Mapbox tiles (not black screen)
- [ ] AC3: Physical Android — map renders correctly
- [ ] AC4: Physical iOS — map renders correctly
- [ ] AC5: With invalid token — `RouteMapPreview` shows map icon + subtitle placeholder (not black rectangle)
- [ ] AC6: With invalid token — `LiveMapWidget` `onMapError` fires; `LiveMapBody` shows SnackBar (verified by code review)
- [ ] AC7: `dart analyze lib/` — 0 errors (pre-existing `_formatKm` warning acceptable)
- [ ] AC8: App launches without crash after all changes

## Manual smoke test (do this before committing)

1. Run on iOS simulator: `flutter run -d <simulator-id>`
2. Navigate to any event detail page
3. Confirm map tiles render (not a black screen)
4. Navigate to a live tracking session (or mock one)
5. Confirm map tiles render in tracking view

## After review: commit command

When satisfied, run:

```bash
git add lib/main.dart ios/Runner/Info.plist lib/shared/widgets/map/route_map_preview.dart lib/features/events/presentation/tracking/widgets/live_map_widget.dart lib/features/events/presentation/tracking/widgets/live_map_body.dart lib/l10n/app_es.arb lib/l10n/app_localizations.dart lib/l10n/app_localizations_es.dart
git commit -m "fix(map): resolve Mapbox black screen on iOS and Android"
```

## Notes from Tech Lead (non-blocking follow-ups)

1. **Localize hardcoded strings in `route_map_preview.dart`** — `'Vista previa del mapa'`, `'Ingresa la dirección para ver la ruta'` (fix grammatical error: `las` → `la`), and `'Ver en mapa'` are pre-existing violations not using `context.l10n`. Move them to `app_es.arb` under `map_` keys in a dedicated cleanup iteration.

2. **Add retry mechanism to `RouteMapPreview` error state** — when `_mapLoadError` is true the placeholder could include a "Reintentar" button that calls `setState(() => _mapLoadError = false)` to let the map re-render. UX improvement for offline/bad-token scenarios.

3. **Filter `onMapLoadErrorListener` by error type in `LiveMapWidget`** — consider only invoking `widget.onMapError` when `data.type == MapLoadErrorType.style` (full style failure) rather than on every tile or sprite error, to reduce false-positive SnackBars during live tracking.

4. **Wire xcconfig for `$(MAPBOX_PUBLIC_TOKEN)` substitution in `Info.plist`** — add `MAPBOX_PUBLIC_TOKEN = pk.eyJ1...` to `ios/Flutter/Debug.xcconfig` and `ios/Flutter/Release.xcconfig` and switch `Info.plist` to use `$(MAPBOX_PUBLIC_TOKEN)`. This aligns iOS with the Android build-variable pattern and avoids a literal token in git blame.

5. **Update `DEPLOY.md`** with the iOS `~/.netrc` setup prerequisite (PRD § 8) — required for any machine running `pod install` for the first time: `machine api.mapbox.com / login mapbox / password {sk.*}`.

6. **Frontend process: run `dart format` before handoff** — two files (`route_map_preview.dart` and `live_map_body.dart`) needed formatting fixes by QA in this iteration. Adding `dart format lib/` as the final Frontend step prevents this.
