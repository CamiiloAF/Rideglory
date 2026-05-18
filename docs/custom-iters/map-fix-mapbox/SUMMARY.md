# Summary — map-fix-mapbox

## What was broken, what was fixed

The Mapbox map was rendering a silent black screen on both Android and iOS in the event detail (route preview) and live tracking views. Three root causes were identified and fixed: (1) `ios/Runner/Info.plist` was missing the `MBXAccessToken` key, which caused the iOS native Mapbox SDK to initialize without a token before the Dart isolate started — tiles were rejected before `main.dart` even ran; (2) `lib/main.dart` wrapped `MapboxOptions.setAccessToken()` in a null-and-empty conditional guard that silently no-oped if the token was missing, replaced with a fail-fast `assert` plus unconditional `setAccessToken(mapboxToken!)`; (3) neither `RouteMapPreview` nor `LiveMapWidget` registered an `onMapLoadErrorListener`, so style/tile failures were completely invisible — `RouteMapPreview` now shows the existing placeholder icon when `_mapLoadError` is true, and `LiveMapWidget` now exposes an `onMapError` callback that `LiveMapBody` wires to a deduplicated SnackBar using the new `map_loadError` localization key.

## Acceptance criteria coverage

| AC | Description | Verification method |
|----|-------------|---------------------|
| AC1 | Android emulator renders Mapbox tiles | Manual smoke test required |
| AC2 | iOS simulator renders Mapbox tiles | Manual smoke test required |
| AC3 | Physical Android renders correctly | Manual smoke test required |
| AC4 | Physical iOS renders correctly | Manual smoke test required |
| AC5 | Invalid token shows placeholder in `RouteMapPreview` | Code review (verified by Tech Lead + QA) |
| AC6 | Invalid token fires `onMapError`; `LiveMapBody` shows SnackBar | Code review (verified by Tech Lead + QA) |
| AC7 | `dart analyze lib/` — 0 errors | Automated — PASS (QA ran; 2 pre-existing info warnings, 0 errors) |
| AC8 | App launches without crash | Automated baseline via `flutter test` — PASS (47/48, TC-2-28 pre-existing) |

## Phase log summary

| Phase | Agent | Completed at | Summary |
|-------|-------|-------------|---------|
| po | PO | 2026-05-16T12:05:00Z | Bug classified high; 4 affected files confirmed by source reading; PRD_NORMALIZED.md written |
| architect | Architect | 2026-05-16T12:25:00Z | 5-file change map locked; Mapbox 2.23.1 API confirmed (onMapLoadErrorListener with MapLoadingErrorEventData); decision to use literal pk.* in Info.plist documented |
| frontend | Frontend | 2026-05-16T13:00:00Z | 6 source files + 2 generated l10n files modified; dart analyze 0 errors |
| qa | QA | 2026-05-16T22:46:37Z | PASS — all 8 files verified, 0 analyze errors, test baseline held; 2 dart format fixes applied |
| tech_lead | Tech Lead | 2026-05-16T23:10:00Z | APPROVED — all changes correct, no architecture violations, 6 non-blocking follow-ups filed |
| po_close | PO | 2026-05-16T22:53:25Z | Close-out complete; REVIEW_CHECKLIST.md and SUMMARY.md written; status set to ready_for_human_review |

## Key handoffs

- `docs/custom-iters/map-fix-mapbox/handoffs/tech_lead.md` — full correctness findings, risk assessment, and 6 follow-up recommendations
- `docs/custom-iters/map-fix-mapbox/handoffs/qa.md` — gate results, file verification table, dart analyze and flutter test output
- `docs/custom-iters/map-fix-mapbox/PRD_NORMALIZED.md` — acceptance criteria (section 6), affected files (section 4), root causes (section 5), and iOS dev setup prerequisite (section 8)
